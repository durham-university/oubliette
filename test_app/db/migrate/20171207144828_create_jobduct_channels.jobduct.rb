# This migration comes from jobduct (originally 20171103110100)
base = ActiveRecord::Migration.respond_to?(:[]) ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration
class CreateJobductChannels < base
  def self.up
    unless table_exists?(:jobduct_channels)
      create_table :jobduct_channels do |t|
        t.string :title           # User readable title for the channel
        t.string :channel_group   # Identifier identifying the group. Usually the id of another resource which owns the channel.
        t.string :status_line     # User readable single line description of what the channel is doing
        t.string :status          # A high level status (running, waiting, finished) and visible to users
        t.string :exec_status     # This is used by channel executor for locks and such together with the above status
        t.string :handler_class   # Class which does the actual work
        t.string :user            # User who started this channel, or the root invoker channel
        t.string :invoker         # Uri of the invoker channel
        t.string :root_invoker    # The last channel in the chain of invokers
        t.string :signal          # For signalling the channel while it's running, used to halt it
        t.string :callback_url    # Where callback will be sent
        t.string :callback_uri    # The uri of the callback object
        t.text :serial_properties # All the other properties of the channel serialised as json
        t.datetime :created_at    # Automatically set timestamp
        t.datetime :updated_at    # Automatically set timestamp
      end
      add_index :jobduct_channels, [:channel_group], name: 'jobduct_channels_by_channel_group'
      add_index :jobduct_channels, [:invoker], name: 'jobduct_channels_by_invoker'
      add_index :jobduct_channels, [:root_invoker], name: 'jobduct_channels_by_root_invoker'
      add_index :jobduct_channels, [:callback_uri], name: 'jobduct_channels_by_callback_uri'
    end
  end

  def self.down
    remove_index :jobduct_channels, name: 'jobduct_channels_by_channel_group'
    remove_index :jobduct_channels, name: 'jobduct_channels_by_invoker'
    remove_index :jobduct_channels, name: 'jobduct_channels_by_root_invoker'
    remove_index :jobduct_channels, name: 'jobduct_channels_by_callback_uri'
    drop_table :jobduct_channels
  end
end