# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataAcquisitionManager do
  let(:slug) { "adzuna" }
  let(:config) { Ingestion::AdapterRegistry.get(slug) }

  describe ".fetchers" do
    it "returns an array of fetcher configurations" do
      fetchers = described_class.fetchers
      expect(fetchers).to be_an(Array)
      expect(fetchers.first).to have_key(:slug)
      expect(fetchers.first).to have_key(:name)
    end
  end

  describe ".status" do
    it "returns the status of a specific fetcher" do
      create(:job_boards_source, slug: slug, name: "Adzuna")
      status = described_class.status(slug)

      expect(status[:slug]).to eq(slug)
      expect(status).to have_key(:can_fetch)
      expect(status).to have_key(:time_until_reset)
    end

    it "returns nil for non-existent fetcher" do
      expect(described_class.status("ghost")).to be_nil
    end
  end

  describe ".run" do
    let!(:source) { create(:job_boards_source, slug: slug) }

    before do
      allow(SystemSetting).to receive(:paused?).and_return(false)
      allow(JobBoards::Syncer).to receive(:new).and_return(instance_double(JobBoards::Syncer, call: true))
    end

    context "with a service object fetcher (Adzuna)" do
      let(:fetcher_double) { instance_double(Adzuna::Fetcher, call: true) }

      before do
        allow(Adzuna::Fetcher).to receive(:new).and_return(fetcher_double)
      end

      it "successfully executes the fetcher and syncs" do
        result = described_class.run(slug, force: true)

        expect(fetcher_double).to have_received(:call).with(force: true)
        expect(result[:success]).to be true

        source.reload
        expect(source.last_ingested_at).to be_present
      end

      it "returns error if global pipelines are paused" do
        allow(SystemSetting).to receive(:paused?).and_return(true)
        result = described_class.run(slug, force: false)
        expect(result[:success]).to be false
        expect(result[:error]).to include("globally paused")
      end
    end

    context "with a Scraper (Indeed)" do
      let(:scraper_slug) { "indeed" }
      let(:client_double) { instance_double(Scraper::Indeed::ApiClient, call: { success: true }) }

      before do
        allow(Scraper::Indeed::ApiClient).to receive(:new).and_return(client_double)
      end

      it "triggers a default search if no queries exist" do
        described_class.run(scraper_slug)

        expect(client_double).to have_received(:call)
      end
    end

    context "with an email source (email_indeed)" do
      let(:email_slug) { "email_indeed" }
      let(:scanner_double) { instance_double(EmailIngestion::Scanner, call: true) }

      before do
        create(:job_boards_source, slug: email_slug)
        allow(EmailIngestion::Scanner).to receive(:new).and_return(scanner_double)
      end

      it "scans only the matching source, not every configured source" do
        described_class.run(email_slug)

        expect(scanner_double).to have_received(:call).with(source: "indeed")
      end
    end

    context "with a generic Scraper (Cord)" do
      let(:scraper_slug) { "cord" }

      it "triggers a default search if no queries exist" do
        allow(Scraper::CrawlDiscoveryJob).to receive(:perform_later)

        described_class.run(scraper_slug)

        expect(Scraper::CrawlDiscoveryJob).to have_received(:perform_later).with(scraper_slug, /cord\.com/, any_args)
      end
    end
  end

  describe ".run_all" do
    it "executes all registered fetchers" do
      # We just want to make sure it iterates and doesn't crash
      allow(described_class).to receive(:run).and_return({ success: true })

      results = described_class.run_all
      expect(results.keys.size).to eq(Ingestion::AdapterRegistry.all.keys.size)
    end
  end
end
