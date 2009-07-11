require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Question do
  before(:each) do
    Question.delete_all
    @valid_attributes = {
      :user_id => 1,
      :pairwise_id => 1,
      :active => false,
      :name => 'name'
    }
  end

  it "should create a new instance given valid attributes" do
    Question.create!(@valid_attributes)
  end

  it 'should create question with name' do
    Question.create!(@valid_attributes.merge(:name => 'name'))
  end

  it 'should not create question with invalid name' do
    Question.create(@valid_attributes.merge(:name => 'Name')).new_record?.should == true
  end
end
