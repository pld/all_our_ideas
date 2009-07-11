require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HomeController do
  before do
    Pairwise.stub!(:voter).and_return([1])
  end

  describe 'index' do
    fixtures :questions, :users

    before do
      @controller.stub!(:set_pairwise_user)
      Pairwise.stub!(:get_question).and_return([1,1,1,1])
    end

#    it 'should get vars' do
#      get :index
#      vars = [
#        assigns[:id1], assigns[:items1], assigns[:question1], assigns[:url1],
#        assigns[:id2], assigns[:items2], assigns[:question2], assigns[:url2]
#      ]
#      vars.length.should == vars.compact.length
#    end
  end

  describe 'login' do
    it 'should call set user based on params' do
      @controller.should_receive(:set_user).with('login', 'password')
      post :login, { :email => 'login', :password => 'password' }
    end

    it 'should ignore get' do
      @controller.should_not_receive(:set_user).with('login', 'password')
      get :login, { :email => 'login', :password => 'password' }
    end

    describe 'with invalid user' do
      before do
        User.delete_all
      end

      it 'should have empty user' do
        post :login, { :email => 'login', :password => 'password' }
        @controller.session[:user].should == nil
      end

      it 'should call reset' do
        @controller.should_receive(:reset_user)
        post :login, { :email => 'login', :password => 'password' }
      end
    end

    describe 'with valid user' do
      fixtures :questions, :users

      it 'should set user' do
        post :login, valid_login_user
        @controller.session[:user].should_not == nil
      end

      it 'should set user login' do
        post :login, valid_login_user
        session[:user][:email].should == valid_login_user[:email]
      end

      it 'should set user password' do
        post :login, valid_login_user
        session[:user][:password].should == 'password'
      end

      it 'should set user encoded password' do
        post :login, valid_login_user
        session[:user][:encoded_pass].should == Base64.encode64('password')
      end
    end

  end
  
  describe 'logout' do
    it 'should reset user' do
      get :logout
      session[:user].should == nil
    end

    it 'should call reset' do
      @controller.should_receive(:reset_user)
      get :logout
    end

    it 'should go to root' do
      get :logout
      response.should be_redirect
    end
  end

  describe 'forgot password' do
    fixtures :users
    
    it 'should render on get' do
      get :forgot_password
      response.should be_success
    end

    it 'should flash error if no user' do
      post :forgot_password
      flash[:error].should_not == nil
    end

    describe 'with valid email' do
      it 'should flash notice' do
        post :forgot_password, :email => User.first.email
        flash[:notice].should_not == nil
      end

      it 'should redirect' do
        post :forgot_password, :email => User.first.email
        response.should be_redirect
      end

      it 'should call mailer' do
        Mailer.should_receive(:deliver_password).with(User.first)
        post :forgot_password, :email => User.first.email
      end
    end
  end
end

def valid_login_user
  { :email => 'r@wk.com', :password => 'password' }
end
