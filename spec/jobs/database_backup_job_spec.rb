# frozen_string_literal: true

require "rails_helper"

RSpec.describe DatabaseBackupJob do
  let(:tmp_backup_dir) { Rails.root.join("tmp/backups_test") }
  let(:job_instance) { described_class.new }

  before do
    FileUtils.mkdir_p(tmp_backup_dir)
    allow(Rails.root).to receive(:join).with("data/backups").and_return(tmp_backup_dir)

    # Use a proper mock for system to satisfy RuboCop RSpec/AnyInstance
    allow(described_class).to receive(:new).and_return(job_instance)
    allow(job_instance).to receive(:system) do |*args|
      dest = args.last
      FileUtils.touch(dest)
      true
    end

    # Setup logger spy
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  after do
    FileUtils.rm_rf(tmp_backup_dir)
  end

  describe "#perform" do
    it "creates backup files and logs success" do
      described_class.perform_now
      expect(Rails.logger).to have_received(:info).with(/\[DatabaseBackup\] Success/).at_least(:once)
      expect(Dir.glob(tmp_backup_dir.join("*.dump")).count).to eq(2)
    end

    it "prunes old backups" do
      old_file = tmp_backup_dir.join("old_backup.dump")
      FileUtils.touch(old_file)
      File.utime(10.days.ago.to_time, 10.days.ago.to_time, old_file)

      described_class.perform_now
      expect(File.exist?(old_file)).to be false
    end

    it "handles errors gracefully" do
      allow(job_instance).to receive(:system).and_raise(StandardError.new("Dump failed"))

      described_class.perform_now
      expect(Rails.logger).to have_received(:error).with(/Critical error: Dump failed/)
    end
  end
end
