class CreateQuestions < ActiveRecord::Migration
  def self.up
    create_table :questions do |t|
      t.integer :user_id, :null => false
      t.integer :pairwise_id, :null => false
      t.boolean :active, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :questions
  end
end
