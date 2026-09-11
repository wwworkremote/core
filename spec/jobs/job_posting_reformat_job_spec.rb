# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobPostingReformatJob do
  let(:job_posting) { create(:job_posting, body: "raw text", data: { "reformatting" => true }) }

  it "calls JobBoards::Reformatter for the given posting" do
    reformatter_double = instance_double(JobBoards::Reformatter, call: true)
    allow(JobBoards::Reformatter).to receive(:new).with(job_posting).and_return(reformatter_double)

    described_class.perform_now(job_posting.id)

    expect(reformatter_double).to have_received(:call)
  end

  it "broadcasts a replace of the description partial after the reformatter runs" do
    allow(JobPosting).to receive(:find).with(job_posting.id).and_return(job_posting)
    allow(JobBoards::Reformatter).to receive(:new).with(job_posting).and_return(instance_double(JobBoards::Reformatter,
                                                                                                call: true))
    allow(job_posting).to receive(:broadcast_replace_to)
    expected_target = ActionView::RecordIdentifier.dom_id(job_posting, :description)

    described_class.perform_now(job_posting.id)

    expect(job_posting).to have_received(:broadcast_replace_to).with(
      job_posting, hash_including(target: expected_target, partial: "job_postings/description")
    )
  end
end
