# This migration comes from jobduct (originally 20171109152300)
base = ActiveRecord::Migration.respond_to?(:[]) ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration
class CreateJobductLogs < base
  def self.up
    unless table_exists?(:jobduct_logs)
      create_table :jobduct_logs do |t|
        t.integer :channel_id
        t.string :highest_level
        t.text :serial_messages
      end
      add_index :jobduct_logs, [:channel_id], name: 'jobduct_logs_by_channel'
    end
  end

  def self.down
    remove_index :jobduct_logs, name: 'jobduct_logs_by_channel'
    drop_table :jobduct_logs
  end
end