class CreateQuestionsVisits < ActiveRecord::Migration
  def self.up
    create_table :questions_visits do |t|
      t.integer :question_id, :null => false
      t.integer :visit_id, :null => false
      t.integer :voter_id_ext, :null => false
      t.integer :prompt_id_ext
      t.timestamps
    end

    add_index :questions_visits, :question_id
    add_index :questions_visits, :visit_id
  end

  def self.down
    drop_table :questions_visits
  end
end
