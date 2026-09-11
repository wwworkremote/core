class AddApplicationTraceIds < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :user_job_postings, :application_trace_id, :string unless column_exists?(:user_job_postings, :application_trace_id)
    add_index :user_job_postings, :application_trace_id, algorithm: :concurrently unless index_exists?(:user_job_postings, :application_trace_id)
    %i[application_field_answers application_field_mappings application_field_observations].each do |table|
      add_column table, :trace_id, :string unless column_exists?(table, :trace_id)
      add_index table, :trace_id, algorithm: :concurrently unless index_exists?(table, :trace_id)
    end
    add_column :extension_error_events, :trace_id, :string unless column_exists?(:extension_error_events, :trace_id)
    add_index :extension_error_events, :trace_id, algorithm: :concurrently unless index_exists?(:extension_error_events, :trace_id)
  end
end
