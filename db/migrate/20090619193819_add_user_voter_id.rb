class AddUserVoterId < ActiveRecord::Migration
  def self.up
    add_column :users, :voter_id, :integer
  end

  def self.down
    remove_column :users, :voter_id
  end
end
