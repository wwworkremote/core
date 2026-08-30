# frozen_string_literal: true

# Supervised replay of a completed guided session (TASK-133). `create` and the
# web `update` commands are Mike's explicit actions; `show` feeds the
# extension banner. Nothing here fills or clicks -- the extension does the
# fill on a confirmed step; this controller only moves the cursor and stops.
class GuidedSessions::ReplaysController < ApplicationController
  rescue_from GuidedSessions::Replay::Error, with: :replay_error

  def show
    render json: replay_state
  end

  COMMANDS = { "advance" => :advance, "approve_gate" => :approve_gate, "stop" => :stop }.freeze

  def create
    driver.start(allow_real_site: ActiveModel::Type::Boolean.new.cast(params[:allow_real_site]))
    redirect_to guided_session_path(session), notice: "Replay started."
  end

  def update
    apply_command
    respond_after_command
  end

  private

  def respond_after_command
    return render(json: replay_state) if request.format.json?

    redirect_to guided_session_path(session), notice: notice_for
  end

  def driver
    @driver ||= GuidedSessions::Replay.new(session)
  end

  def session
    @session ||= GuidedSession.find(params.expect(:guided_session_id))
  end

  def replay
    @replay ||= session.guided_session_replays.find(params.expect(:id))
  end

  def apply_command
    command = COMMANDS.fetch(params.expect(:command)) { raise GuidedSessions::Replay::Error, "unknown replay command" }
    driver.public_send(command, replay)
  end

  def notice_for
    { "approve_gate" => "Gate approved -- replay ended, over to you.", "stop" => "Replay stopped." }
      .fetch(params[:command], "Replay advanced.")
  end

  def replay_state
    { replay: replay.slice(:id, :status, :current_step, :allow_real_site),
      instruction: driver.next_step(replay) }
  end

  def replay_error(error)
    respond_to do |format|
      format.json { render json: { error: error.message }, status: :unprocessable_content }
      format.html { redirect_to guided_session_path(session), alert: error.message }
    end
  end
end
