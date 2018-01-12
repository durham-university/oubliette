# This migration comes from jobduct (originally 20171106092100)
base = ActiveRecord::Migration.respond_to?(:[]) ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration
class CreateJobductCallbacks < base
  def self.up
    unless table_exists?(:jobduct_callbacks)
      create_table :jobduct_callbacks do |t|
        t.integer :channel_id
        t.string :title
        t.string :call_url
        t.string :remote_uri
        t.string :status
        t.string :success_code
        t.datetime :sent_at
        t.datetime :received_at
        t.datetime :processed_at
        t.text :serial_sent_payload
        t.text :serial_return_payload
      end
      add_index :jobduct_callbacks, [:channel_id], name: 'jobduct_callbacks_by_channel'
    end
  end

  def self.down
    remove_index :jobduct_callbacks, name: 'jobduct_callbacks_by_channel'
    drop_table :jobduct_callbacks
  end
end