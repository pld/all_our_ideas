require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe QuestionsController do
  before do
    Pairwise.stub!(:voter).and_return([1])
  end

  it "should require set user" do
    get :index
    response.should be_redirect
  end

  describe 'with user' do
    fixtures :questions, :users
    
    before do
      @controller.set_user('r@wk.com', 'password')
      Pairwise.stub!(:list_questions).and_return([['1']])
    end

    describe 'index' do
      it 'should set questions' do
        get :index
        assigns[:questions].should_not == nil
      end
    end

    describe 'new' do
      fixtures :questions
      
      it 'should render' do
        get :new
        response.should be_success
      end
    end

    describe 'create' do
      before do
        Pairwise.stub!(:question).and_return([200])
      end

      describe 'with invalid data' do
        it 'should error on nil question text' do
          post :create
          assigns[:question].errors[:question_text].should_not == nil
        end

        it 'should error on empty question text' do
          post :create, :question => { :question_text => '' }
          assigns[:question].errors[:question_text].should_not == nil
        end

        it 'should error on question text > max' do
          post :create, :question => { :question_text => Array.new(Const::MAX_QUESTION_LENGTH + 1).inject('') { |s,e| s += "a" } }
          assigns[:question].errors[:question_text].should_not == nil
        end

        it 'should error on empty question text and valid question' do
          post :create, :question => { :name => 'aaa', :question_text => '' }
          assigns[:question].errors[:question_text].should_not == nil
        end

        it 'should error on empty question text and invalid question' do
          post :create, :question => { :name => '///' }
          assigns[:question].errors[:name].should_not == nil
        end

        it 'should error on empty name' do
          post :create, :question_text => '', :question => { :name => '' }
          assigns[:question].errors[:name].should_not == nil
        end

        it 'should not redirect to new on valid question text and invalid question' do
          post :create, :question => { :name => '///', :question_text => 'q' }
          response.should_not be_redirect
        end
      end

      describe 'with valid data' do
        it 'should create question' do
          post :create, :question => { :name => 'q', :question_text => 'q' }
          Question.last.pairwise_id.should == 200
        end

        it 'should set user id' do
          post :create, :question => { :name => 'q', :question_text => 'q' }
          Question.last.user_id.should == 1
        end

        it 'should redirect on create' do
          post :create, :question => { :name => 'q', :question_text => 'q' }
          response.should redirect_to("http:///q?p=1")
        end

        it 'should set name' do
          post :create, :question => { :name => 'q', :question_text => 'q' }
          Question.last.name.should == 'q'
        end

        it 'should downcase name' do
          post :create, :question => { :name => 'Q', :question_text => 'q' }
          Question.last.name.should == 'q'
        end

        it 'should set question text' do
          post :create, :question => { :name => 'q', :question_text => 'q' }
          assigns[:question].question_text.should == 'q'
        end

        it 'should set sanitized question text' do
          post :create, :question => { :name => 'q', :question_text => '<a>q</a>' }
          assigns[:question].question_text.should == 'q'
        end

        it 'should set question name' do
          post :create, :question => { :name => 'q', :question_text => 'q'  }
          assigns[:question].name.should == 'q'
        end

        it 'should set question pairid' do
          post :create, :question => { :name => 'q', :question_text => 'q' }
          assigns[:question].pairwise_id.should == 200
        end

        it 'should set question user id' do
          post :create, :question => { :name => 'q', :question_text => 'q' }
          assigns[:question].user_id.should == 1
        end
      end
    end

    describe 'show' do
      it 'should redirect if not id' do
        get :show
        response.should be_redirect
      end

      it 'should flash error if no id' do
        get :show
        flash[:error].should_not == nil
      end

      it 'should flash error if no user id' do
        get :show, :id => 3
        flash[:error].should_not == nil
      end

      describe 'with good id' do
        before do
          Pairwise.stub!(:get_question).and_return([1, 'test', 1, 1, 1])
          Pairwise.stub!(:list_votes).and_return([["143758", "591539", "0", "127.0.0.1", "5400", "3360"], ["143760", "591541", "0", "127.0.0.1", "4201", nil], ["143762", "591543", "0", "127.0.0.1", "2319", nil], ["143763", "591544", "0", "127.0.0.1", "3235", nil], ["143764", "591545", "0", "127.0.0.1", "12552", nil]])
          Pairwise.stub!(:list_items).and_return([1])
        end

        it 'should fill vars' do
          get :show, :id => 1
          vs = [assigns[:id], assigns[:question], assigns[:items_count], assigns[:votes_count], assigns[:label], assigns[:explain]]
          vs.length.should == vs.compact.length
        end

        it 'should set items' do
          get :show, :id => 1
          assigns[:items].should == [1]
        end

        it 'should set ip_percents' do
          get :show, :id => 1
          assigns[:ip_percents].should_not == nil
        end

        it 'should set question internal' do
          get :show, :id => 1
          assigns[:question_internal].should_not == nil
        end

        it 'should set short name' do
          get :show, :id => 2
          assigns[:named_url].should =~ /#{Question.find(2).name}/
        end
      end
    end

    describe 'edit' do
      before do
        Pairwise.stub!(:get_question).and_return([1, 'test', 1, 1, 1])
        Pairwise.stub!(:list_votes).and_return([["143758", "591539", "0", "127.0.0.1", "5400", "3360"], ["143760", "591541", "0", "127.0.0.1", "4201", nil], ["143762", "591543", "0", "127.0.0.1", "2319", nil], ["143763", "591544", "0", "127.0.0.1", "3235", nil], ["143764", "591545", "0", "127.0.0.1", "12552", nil]])
        Pairwise.stub!(:list_items).and_return([1])
        get :edit, :id => 1
      end

      it 'should fill vars' do
        vs = [assigns[:id], assigns[:question], assigns[:items_count], assigns[:votes_count]]
        vs.length.should == vs.compact.length
      end

      it 'should set question internal' do
        assigns[:question_internal].should_not == nil
      end
    end

    describe 'update' do
      before do
        Pairwise.stub!(:get_question).and_return([1, 'test', 1, 1, 1])
        Pairwise.stub!(:list_votes).and_return([["143758", "591539", "0", "127.0.0.1", "5400", "3360"], ["143760", "591541", "0", "127.0.0.1", "4201", nil], ["143762", "591543", "0", "127.0.0.1", "2319", nil], ["143763", "591544", "0", "127.0.0.1", "3235", nil], ["143764", "591545", "0", "127.0.0.1", "12552", nil]])
        Pairwise.stub!(:list_items).and_return([1])
      end

      describe 'with valid data' do
        it 'should update name' do
          post :update, :id => 1, :question => { :name => 'name' }
          Question.find(1).name.should == 'name'
        end

        it 'should downcase name' do
          post :update, :id => 1, :question => { :name => 'NAME' }
          Question.find(1).name.should == 'name'
        end

        it 'should set flash' do
          post :update, :id => 1, :question => { :name => 'name' }
          flash[:notice].should_not == nil
        end

        it 'should redirect' do
          post :update, :id => 1, :question => { :name => 'name' }
          response.should be_redirect
        end

        it 'should not allow nil' do
          post :update, :id => 1, :question => { :name => nil }
          response.should_not be_redirect
        end

        it 'should not allow no param' do
          post :update, :id => 1
          response.should_not be_redirect
        end
      end

      describe 'with invalid data' do
        before do
          post :update, :id => 1, :question => { :name => Question.last.name }
        end
        
        it 'should fill vars' do
          vs = [assigns[:id], assigns[:question], assigns[:items_count], assigns[:votes_count]]
          vs.length.should == vs.compact.length
        end

        it 'should set question internal' do
          assigns[:question_internal].should_not == nil
        end
      end
    end
    
    describe 'state' do
      it 'should redirect if not id' do
        get :state
        response.should be_redirect
      end

      it 'should redirect if no user id' do
        get :state, :id => 3
        response.should be_redirect
      end

      it "should set flash error if doesn't own question" do
        get :state, :id => 3
        flash[:error].should_not == nil
      end

      describe 'with good id' do
        it 'should set question to param' do
          get :state, :id => 1, :active => 0
          Question.find(1).active.should == false
        end

        it 'should redirect' do
          get :state, :id => 1, :active => 0
          response.should be_redirect
        end

        it 'should flash notice if being activated' do
          get :state, :id => 1, :active => 1
          flash[:notice].should_not == nil
        end

        it 'should not flash notice if not being activated' do
          get :state, :id => 1, :active => 0
          flash[:notice].should == nil
        end
      end
    end

    describe 'export' do
      before do
        @items = [
          [3359,'wathiiqa',1,1416,1,0,"May 27, 2009 09:36",1,0],
          [3358,'tajriba',1,1441,4,1,"May 27, 2009 09:29",5,0],
          [3354,'amalii',1,1414,2,1,"May 27, 2009 09:24",3,0],
          [3357,'hhadiith',1,1395,3,3,"May 27, 2009 09:27",6,0],
          [3355,'khubaara',1,1388,2,3,"May 27, 2009 09:25",5,0],
          [3356,'mamuur',1,1376,2,3,"May 27, 2009 09:26",5,0]
        ]
        Pairwise.stub!(:list_items).and_return(@items)
      end

      it 'should export item for question' do
        get :export, :id => 1
        response.should be_success
      end

      it 'should flash success' do
        get :export, :id => 1
        flash[:notice].should_not == nil
      end
    end
  end
end
