# This migration comes from jobduct (originally 20180326150000)
base = ActiveRecord::Migration.respond_to?(:[]) ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration
class ChangeJobductChannelsSerialPropertiesMaxLength < base
  # Change serial_properties column max size limit to be big enough
  def change
    change_column :jobduct_channels, :serial_properties, :text, limit: 1073741823
  end
end
