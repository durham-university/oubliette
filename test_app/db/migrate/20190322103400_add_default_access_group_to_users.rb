class AddDefaultAccessGroupToUsers < ActiveRecord::Migration
  def change
    add_column :users, :default_access_group, :string
  end
end
