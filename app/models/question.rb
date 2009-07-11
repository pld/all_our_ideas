class Question < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :question_text, :if => lambda { |q| !q.pairwise_id }
  validates_length_of :question_text, :maximum => Const::MAX_QUESTION_LENGTH, :if => lambda { |q| !q.pairwise_id }
  validates_presence_of :name
  validates_uniqueness_of :name, :if => lambda { |q| q.name }
  validates_format_of :name, :with => /\A([a-z]|-|_)*\z/
  validates_presence_of :user_id, :if => lambda { |q| q.pairwise_id }
  validates_presence_of :pairwise_id, :if => lambda { |q| q.user_id }
  validates_uniqueness_of :pairwise_id, :if => lambda { |q| q.user_id }

  def self.human_attribute_name(attribute_key_name)
    if attribute_key_name.to_sym == :name
      "Step 2"
    elsif attribute_key_name.to_sym == :question_text
      "Step 1"
    else
      super
    end
  end

  attr_accessor :question_ideas, :question_text
end
