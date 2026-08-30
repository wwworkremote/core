# frozen_string_literal: true

# TASK-126 / ADR 010: the extension POSTs one raw guided-session asset (or a
# capture-gap note) here, one at a time, during a guided session. Rails writes
# it under data/datalake/sessions/<session_token>/ and owns manifest.json.
# Mirrors Api::GuidedSessionEventsController -- Rails.env.local? only, no auth.
class Api::DatalakeAssetsController < ApplicationController
  skip_before_action :authenticate_admin
  skip_before_action :verify_authenticity_token

  def create
    return head :not_found unless Rails.env.local?

    params[:gap].present? ? record_gap : record_asset
  end

  private

  def store
    @store ||= Datalake::AssetStore.new(session.session_token)
  end

  def session
    @session ||= GuidedSession.find_by!(session_token: params.expect(:session_token))
  end

  def record_asset
    return render(json: { error: "unknown asset type" }, status: :unprocessable_content) unless known_type?

    entry = written_asset
    point_event_at(entry)
    render json: { success: true, asset: entry }, status: :created
  end

  def known_type? = Datalake::AssetStore::TYPES.include?(asset_params[:type])

  def written_asset
    p = asset_params
    store.write_asset(type: p[:type], event_id: p[:guided_session_event_id].to_i, bytes: decoded(p[:content_base64]))
  end

  def decoded(content_base64) = Base64.decode64(content_base64.to_s)

  # AC#3: the event carries a pointer back to its manifest entries.
  def point_event_at(entry)
    session.guided_session_events.find_by(id: asset_params[:guided_session_event_id])&.note_datalake_asset(entry["seq"])
  end

  def record_gap
    render json: { success: true, gap: written_gap }, status: :created
  end

  def written_gap
    store.write_gap(type: gap_params[:type], event_id: gap_params[:guided_session_event_id].to_i,
                    reason: gap_params[:reason])
  end

  def asset_params
    @asset_params ||= params.expect(asset: %i[type guided_session_event_id content_base64])
  end

  def gap_params
    @gap_params ||= params.expect(gap: %i[type guided_session_event_id reason])
  end
end
