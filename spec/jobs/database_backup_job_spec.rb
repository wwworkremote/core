# frozen_string_literal: true

require "rails_helper"

RSpec.describe DatabaseBackupJob do
  let(:tmp_backup_dir) { Rails.root.join("tmp/backups_test") }

  before do
    FileUtils.mkdir_p(tmp_backup_dir)
    allow(Rails.root).to receive(:join).with("data/backups").and_return(tmp_backup_dir)
    # Stub system call but we must create the file it would have created
    allow_any_instance_of(described_class).to receive(:system) do |_instance, *args|
      # Extract the filename from args (it is the last one usually)
      dest = args.last
      FileUtils.touch(dest)
      true
    end
  end

  after do
    FileUtils.rm_rf(tmp_backup_dir)
  end

  describe "#perform" do
    it "creates backup files and logs success" do
      expect(Rails.logger).to receive(:info).with(/\[DatabaseBackup\] Success/).at_least(:once)
      described_class.perform_now
      expect(Dir.glob(tmp_backup_dir.join("*.dump")).count).to eq(2)
    end

    it "prunes old backups" do
      old_file = tmp_backup_dir.join("old_backup.dump")
      FileUtils.touch(old_file)
      File.utime(10.days.ago, 10.days.ago, old_file)

      described_class.perform_now
      expect(File.exist?(old_file)).to be false
    end

    it "handles errors gracefully" do
      allow_any_instance_of(described_class).to receive(:system).and_raise(StandardError.new("Dump failed"))
      expect(Rails.logger).to receive(:error).with(/Critical error: Dump failed/)
      described_class.perform_now
    end
  end
end
