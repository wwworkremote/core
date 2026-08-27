# frozen_string_literal: true

class GuidedSessionsController < ApplicationController
  before_action :set_guided_session, only: :show

  def show; end

  def new
    @guided_session = GuidedSession.new
  end

  def create
    @guided_session = GuidedSession.new(guided_session_params)

    return redirect_to guided_session_path(@guided_session), notice: "Guided session started." if @guided_session.save

    render :new, status: :unprocessable_content
  end

  private

  def set_guided_session
    @guided_session = GuidedSession.find(params.expect(:id))
  end

  def guided_session_params
    params.expect(guided_session: [:source_url])
  end
end
