# frozen_string_literal: true

class AddNameToSolidQueueProcesses < ActiveRecord::Migration[8.2]
  def change
    add_column :solid_queue_processes, :name, :string
  end
end
