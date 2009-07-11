require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe QuestionsVisit do
  before(:each) do
    @valid_attributes = {
      :question_id => 1,
      :visit_id => 1,
      :voter_id_ext => 1
    }
  end

  it "should create a new instance given valid attributes" do
    QuestionsVisit.create!(@valid_attributes)
  end

  it 'should require uniq prompt id ext' do
    QuestionsVisit.new(@valid_attributes).valid?.should == false
  end

  it 'should find by q v' do
    QuestionsVisit.qv(1,1).should_not == nil
  end
end
