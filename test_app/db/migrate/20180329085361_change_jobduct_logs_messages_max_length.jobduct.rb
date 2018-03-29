# This migration comes from jobduct (originally 20180326150200)
base = ActiveRecord::Migration.respond_to?(:[]) ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration
class ChangeJobductLogsMessagesMaxLength < base
  # Change serial_properties column max size limit to be big enough
  def change
    change_column :jobduct_callbacks, :serial_sent_payload, :text, limit: 1073741823
    change_column :jobduct_callbacks, :serial_return_payload, :text, limit: 1073741823
  end
end
