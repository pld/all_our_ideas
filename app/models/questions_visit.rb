class QuestionsVisit < ActiveRecord::Base
  belongs_to :question
  belongs_to :visit

  validates_presence_of :question_id
  validates_presence_of :visit_id
  validates_presence_of :voter_id_ext
  validates_uniqueness_of :voter_id_ext
  validates_uniqueness_of :prompt_id_ext, :if => lambda { |r| r.prompt_id_ext }

  def self.qv(qid, vid)
     first(:conditions => { :question_id => qid, :visit_id => vid })
  end
end
