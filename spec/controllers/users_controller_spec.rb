require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UsersController do
  before do
    Pairwise.stub!(:voter).and_return([1])
  end
  
  describe 'index' do
    fixtures :questions

    it "should require set user" do
      get :index
      response.should be_redirect
    end

    describe 'with user' do
      before do
        @controller.set_user('login', 'password')
        Pairwise.stub!(:list_votes).and_return([["143758", "591539", "0", "127.0.0.1", "5400", "3360"], ["143760", "591541", "0", "127.0.0.1", "4201", nil], ["143762", "591543", "0", "127.0.0.1", "2319", nil], ["143763", "591544", "0", "127.0.0.1", "3235", nil], ["143764", "591545", "0", "127.0.0.1", "12552", nil]])
        Pairwise.stub!(:list_questions).and_return([['1']])
      end

      it 'should set questions' do
        get :index
        assigns[:questions].should_not == nil
      end

      it 'should set vars' do
        get :index
        vs = [assigns[:ip_percents], assigns[:label], assigns[:explain]]
        vs.length.should == vs.compact.length
      end
    end
  end

  describe 'new' do
    it 'should do nothing on get' do
      get :new
      assigns[:user].should == nil
    end

    describe 'post' do
      before do
        User.delete_all
      end
      
      describe 'on pairwise success' do
        before do
          Pairwise.stub!(:user).and_return([1])
        end

        it 'should instantiante user' do
          post :new, :user => { :email => 'r@a.wk', :password => 'password' }
          assigns[:user].should be_an_instance_of(User)
        end

        it 'should instantiante user from params' do
          post :new, :user => { :email => 'r@a.wk', :password => 'password' }
          assigns[:user].email == 'r@a.wk' && assigns[:user].password == 'password'
        end

        it 'should not assign flash error if user invalid' do
          post :new, :user => { :email => 'r@a.wk', :password => 'password' }
          flash[:error].should == nil
        end

        it 'should not save user if invalid' do
          post :new, :user => { :email => 'r@a.wk', :password => 'password' }
          assigns[:user].new_record?.should == true
        end

        describe 'with valid user' do
          it 'should save' do
            post :new, :user => valid_user
            assigns[:user].new_record?.should == false
          end

          it 'should set user' do
            post :new, :user => valid_user
            @controller.user_set?.should == true
          end

          it 'should redirect' do
            post :new, :user => valid_user
            response.should be_redirect
          end
        end
      end

      describe 'on pairwise failure' do
        before do
          Pairwise.stub!(:user).and_return([0])
        end

        it 'should set flash error' do
          post :new, :user => valid_user
          flash[:error].should_not == nil
        end
      end
    end
  end
end

private
  def valid_user
    { :password => 'password', :password_confirmation => 'password',  :email => 'r@wk.com' }
  end