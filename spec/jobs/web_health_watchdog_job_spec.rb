# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebHealthWatchdogJob do
  let(:job_instance) { described_class.new }
  let(:fail_file) { described_class::FAIL_FILE }

  before do
    FileUtils.rm_f(fail_file)
    allow(described_class).to receive(:new).and_return(job_instance)
    # Kernel#system: default true (agent loaded / kickstart succeeds); specs
    # assert on the exact argv.
    allow(job_instance).to receive(:system).and_return(true)
  end

  after { FileUtils.rm_f(fail_file) }

  def stub_probe(alive:)
    if alive
      allow(Net::HTTP).to receive(:start).and_return(:ok)
    else
      allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNREFUSED)
    end
  end

  it "does nothing when the launchd agent is not loaded" do
    allow(job_instance).to receive(:system).with("launchctl", "list", described_class::LABEL,
                                                 any_args).and_return(false)
    stub_probe(alive: false)

    described_class.perform_now

    expect(job_instance).not_to have_received(:system).with("launchctl", "kickstart", any_args)
  end

  it "clears the failure counter while puma answers" do
    fail_file.write("1")
    stub_probe(alive: true)

    described_class.perform_now

    expect(fail_file).not_to exist
  end

  it "does not restart on a single miss" do
    stub_probe(alive: false)

    described_class.perform_now

    expect(fail_file.read).to eq("1")
    expect(job_instance).not_to have_received(:system).with("launchctl", "kickstart", any_args)
  end

  it "kickstarts the service after two consecutive misses" do
    stub_probe(alive: false)

    described_class.perform_now
    described_class.perform_now

    expect(job_instance).to have_received(:system).with(
      "launchctl", "kickstart", "-k", "gui/#{Process.uid}/#{described_class::LABEL}", any_args
    )
    expect(fail_file).not_to exist
  end
end
