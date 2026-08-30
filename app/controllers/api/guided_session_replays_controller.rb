# frozen_string_literal: true

# TASK-133: the extension's view of an active replay, by session token.
# GET returns the current fill/gate/done instruction for the banner; PATCH
# runs advance / approve_gate / stop -- each is Mike clicking a banner button,
# never the extension acting on its own. Rails.env.local? only, no auth.
class Api::GuidedSessionReplaysController < ApplicationController
  skip_before_action :authenticate_admin
  skip_before_action :verify_authenticity_token
  before_action :require_local
  before_action :require_active_replay, only: :update
  rescue_from GuidedSessions::Replay::Error, with: :replay_error

  COMMANDS = %w[advance approve_gate stop].freeze

  def show
    replay ? render(json: state) : render(json: { active: false })
  end

  def update
    run_command
    render json: state
  end

  private

  def require_local
    head :not_found unless Rails.env.local?
  end

  def require_active_replay
    render(json: { error: "no active replay" }, status: :unprocessable_content) unless replay
  end

  def session
    @session ||= GuidedSession.find_by!(session_token: params.expect(:session_token))
  end

  def replay
    @replay ||= session.guided_session_replays.active.first
  end

  def driver
    @driver ||= GuidedSessions::Replay.new(session)
  end

  def run_command
    command = params.expect(:command)
    raise GuidedSessions::Replay::Error, "unknown replay command" unless COMMANDS.include?(command)

    driver.public_send(command, replay)
  end

  def state
    { active: replay.active?, replay: replay.slice(:id, :status, :current_step), instruction: driver.next_step(replay) }
  end

  def replay_error(error)
    render json: { error: error.message }, status: :unprocessable_content
  end
end
