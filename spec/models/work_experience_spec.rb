# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkExperience do
  describe "#embeddable_text" do
    subject(:experience) do
      create(:work_experience, title: "Principal Developer", company_name: "BDI",
                               summary: "Owned technical strategy.", skills: "C#, ASP.NET, Subversion")
    end

    before do
      experience.experience_highlights.create!(label: "Delivery", text: "Introduced CruiseControl.NET for CI.")
    end

    it "includes highlight text" do
      expect(experience.reload.embeddable_text).to include("Introduced CruiseControl.NET for CI.")
    end

    # The skills list is the only place most technology names appear -- 95% of
    # them are in no other field on the record -- so leaving it out made those
    # terms unretrievable.
    it "includes the skills list" do
      expect(experience.embeddable_text).to include("C#, ASP.NET, Subversion")
    end

    it "omits blank parts rather than emitting empty segments" do
      experience.update!(summary: nil)

      expect(experience.reload.embeddable_text).not_to include(". . ")
    end
  end

  describe "embedding enqueue" do
    before { ActiveJob::Base.queue_adapter = :test }

    it "enqueues when embeddable text changes" do
      experience = create(:work_experience)

      expect { experience.update!(skills: "Ruby, Rails") }
        .to have_enqueued_job(Resume::WorkExperienceEmbeddingJob).with(experience.id)
    end

    it "does not enqueue when a non-embeddable attribute changes" do
      experience = create(:work_experience)

      expect { experience.update!(location: "Remote") }
        .not_to have_enqueued_job(Resume::WorkExperienceEmbeddingJob)
    end
  end
end
