# This migration comes from jobduct (originally 20180326150200)
base = ActiveRecord::Migration.respond_to?(:[]) ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration
class ChangeJobductLogsMessagesMaxLength < base
  # Change serial_messages column max size limit to be big enough
  def change
    change_column :jobduct_logs, :serial_messages, :text, limit: 1073741823
  end
end
