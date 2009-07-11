class AddUsersEmail < ActiveRecord::Migration
  def self.up
    add_column :users, :email, :string, :null => false
  end

  def self.down
    remove_column :users, :email, :string
  end
end
