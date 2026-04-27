# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  describe "GET /admin" do
    it "returns a success response" do
      get admin_root_path
      expect(response).to be_successful
      expect(response.body).to include("System_Administration")
    end
  end

  describe "POST /admin/toggle_pause" do
    it "toggles the pipeline pause state" do
      expect(SystemSetting.paused?).to be false
      
      post admin_toggle_pause_path
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to include("Emergency Brake Engaged")
      expect(SystemSetting.paused?).to be true

      post admin_toggle_pause_path
      expect(flash[:notice]).to include("resumed")
      expect(SystemSetting.paused?).to be false
    end
  end
end
