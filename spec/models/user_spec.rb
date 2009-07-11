require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do
  before(:each) do
    @valid_attributes = {
      :password => 'pass',
      :password_confirmation => 'pass',
      :email => 'r@a.wk'
    }
    User.delete_all
  end

  it "should create a new instance given valid attributes" do
    User.create!(@valid_attributes)
  end

  it 'should encode password before create' do
    user = User.create!(@valid_attributes)
    user.encoded_password.should == Base64.encode64('pass')
  end

  it 'should encode password before create' do
    user = User.create!(@valid_attributes)
    user.decoded_password.should == 'pass'
  end

  it 'should not encode password before save' do
    user = User.create!(@valid_attributes)
    user.should_not_receive(:encode_password)
    user.update_attribute(:email, "v@a.wk")
  end

  describe 'voter id' do
    before do
      @user = User.create!(@valid_attributes)
      Pairwise.stub!(:voter).and_return([1])
    end

    it 'should save voter id' do
      @user.voter_id.should == nil
      @user.voter_id!
      @user.voter_id.should == 1
    end

    it 'should not resave voter id' do
      @user.update_attribute(:voter_id, 2)
      @user.voter_id!
      @user.voter_id.should == 2
    end

  end
end
