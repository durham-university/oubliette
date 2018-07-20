# This migration comes from jobduct (originally 20180601124700)
base = ActiveRecord::Migration.respond_to?(:[]) ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration
class CreateJobductActions < base
  def self.up
    unless table_exists?(:jobduct_actions)
      create_table :jobduct_actions do |t|
        t.integer :callback_id
        t.text :serial_payload, limit: 1073741823
        t.datetime :created_at
      end
      add_index :jobduct_actions, :callback_id, name: 'jobduct_actions_by_callback'
    end
  end

  def self.down
    remove_index :jobduct_actions, name: 'jobduct_actions_by_callback'
    drop_table :jobduct_actions
  end
end