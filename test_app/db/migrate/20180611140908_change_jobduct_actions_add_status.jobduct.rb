# This migration comes from jobduct (originally 20180607150400)
base = ActiveRecord::Migration.respond_to?(:[]) ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration
class ChangeJobductActionsAddStatus < base
  # Change serial_messages column max size limit to be big enough
  def change
    add_column :jobduct_actions, :status, :string
  end
end
