# This migration comes from jobduct (originally 20180911111000)
base = ActiveRecord::Migration.respond_to?(:[]) ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration
class ChangeJobductCallbacksCallbackParams < base
  def change
    add_column :jobduct_callbacks, :serial_callback_params, :text, limit: 1073741823
  end
end
