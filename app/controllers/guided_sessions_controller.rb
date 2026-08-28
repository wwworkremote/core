# frozen_string_literal: true

class GuidedSessionsController < ApplicationController
  # Playback position is local presentation state; it cannot submit, alter,
  # or transmit a provider/application action.
  skip_before_action :verify_authenticity_token, only: :playback
  before_action :set_guided_session, only: %i[show playback]

  def show
    @events = @guided_session.guided_session_events.order(:occurred_at, :id)
  end

  def new
    @guided_session = GuidedSession.new
  end

  def create
    @guided_session = GuidedSession.new(guided_session_params)

    return redirect_to guided_session_path(@guided_session), notice: "Guided session started." if @guided_session.save

    render :new, status: :unprocessable_content
  end

  def playback
    position = Integer(params.expect(:position), exception: false)
    return render_invalid_position if invalid_position?(position)

    @guided_session.update!(playback_position: position)
    render json: { success: true, position: @guided_session.playback_position }
  end

  private

  def set_guided_session
    @guided_session = GuidedSession.find(params.expect(:id))
  end

  def guided_session_params
    params.expect(guided_session: [:source_url])
  end

  def invalid_position?(position)
    position.nil? || position.negative?
  end

  def render_invalid_position
    render json: { errors: ["Position must be a non-negative integer"] }, status: :unprocessable_content
  end
end
