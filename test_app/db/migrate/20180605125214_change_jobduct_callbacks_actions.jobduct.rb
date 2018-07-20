# This migration comes from jobduct (originally 20180601112900)
base = ActiveRecord::Migration.respond_to?(:[]) ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration
class ChangeJobductCallbacksActions < base
  def change
    rename_column :jobduct_callbacks, :received_at, :finished_at
    add_column :jobduct_callbacks, :last_action_at, :datetime
    add_column :jobduct_callbacks, :serial_queued_actions, :text, limit: 1073741823
  end
end
