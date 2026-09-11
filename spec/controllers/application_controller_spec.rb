# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController do
  describe "#authenticate_admin" do
    controller do
      def index
        render plain: "ok"
      end
    end

    before do
      routes.draw { get "index" => "anonymous#index" }
    end

    it "skips authentication in the test environment" do
      get :index
      expect(response).to be_successful
    end

    context "outside the test environment" do
      before do
        allow(Rails.env).to receive_messages(test?: false, development?: false)
      end

      it "skips authentication in development" do
        allow(Rails.env).to receive_messages(development?: true)
        get :index
        expect(response).to be_successful
      end

      it "challenges for HTTP basic auth" do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end

      it "authenticates with the correct credentials" do
        request.env["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials(
          ENV.fetch("ADMIN_EMAIL", "mike@just3ws.com"), ENV.fetch("ADMIN_PASSWORD", "password")
        )
        get :index
        expect(response).to be_successful
      end

      it "rejects incorrect credentials" do
        request.env["HTTP_AUTHORIZATION"] =
          ActionController::HttpAuthentication::Basic.encode_credentials("wrong", "wrong")
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "#available_chat_models" do
    controller do
      def index
        render plain: available_chat_models.map(&:name).join(",")
      end
    end

    before { routes.draw { get "index" => "anonymous#index" } }

    it "prioritizes ollama-provider models when models exist in the database" do
      create(:model, name: "gpt-4", provider: "openai", model_id: "gpt-4")
      create(:model, name: "llama3", provider: "ollama", model_id: "llama3")

      get :index

      expect(response.body.split(",").first).to eq("llama3")
    end
  end
end
