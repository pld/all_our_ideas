require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe VoteController do
  fixtures :questions, :users, :questions_visits, :visits

  before do
    Pairwise.stub!(:voter).and_return([1])
  end

  describe 'index' do    
    before do
      Pairwise.stub!(:get_question).and_return(1, 'test')
      Pairwise.stub!(:list_items).and_return([])
      Pairwise.stub!(:list_votes).and_return([])
    end
    
    it 'should set responses' do
      get :index, :question_id => 1
      assigns[:responses].should_not == nil
    end
  end

  describe 'show' do
    it 'should redirect if no id' do
      get :show
      response.should be_redirect
    end

    it 'should set vars' do
      Pairwise.stub!(:get_question).and_return([1, 'test', 1, 1])
      Pairwise.stub!(:get_prompt).and_return([[1,2]])
      Pairwise.should_receive(:get_item).with(1).and_return('one')
      Pairwise.should_receive(:get_item).with(2).and_return('two')
      get :show, :id => 1
      vs = [assigns[:question_id], assigns[:question], assigns[:items_count], assigns[:votes_count]]
      vs.length.should == vs.compact.length
    end

    describe 'failing return' do
      before do
        QuestionsVisit.delete_all
      end

      it 'should not set cached vars' do
        get :show, :id => 1
        vs = [assigns[:prompt_id], assigns[:item_ids], assigns[:item_data]]
        vs.compact.length.should == 0
      end
    end
    describe 'without cached prompt' do
      before do
        QuestionsVisit.delete_all
        Pairwise.stub!(:prompt).and_return([[1], [[1,2]], [['one','two']]])
      end

      it 'should set cached vars' do
        get :show, :id => 1
        vs = [assigns[:prompt_id], assigns[:item_ids], assigns[:item_data]]
        vs.compact.length.should == 3
      end

      it 'should not set last prompt' do
        get :show, :id => 1
        vs = [assigns[:winner_id], assigns[:winner], assigns[:loser_id], assigns[:loser], assigns[:skip]]
        vs.compact.length.should == 0
      end

      it 'should set last prompt to nil' do
        get :show, :id => 1
        @controller.session[:last_prompt].should == nil
      end

      it 'should not set response time' do
        get :show, :id => 1
        @controller.session[:prompt_time].should_not == nil
      end
    end

    describe 'with cached prompt' do
      before do
        @controller.should_receive(:current_visit!).and_return(Visit.first)
        Pairwise.stub!(:get_prompt).and_return([[1,2]])
        Pairwise.should_receive(:get_item).with(1).and_return('one')
        Pairwise.should_receive(:get_item).with(2).and_return('two')
      end

      it 'should set cache vars' do
        get :show, :id => 1
        vs = [assigns[:prompt_id], assigns[:item_ids], assigns[:item_data]]
        vs.length.should == vs.compact.length
      end
    end
    
    describe 'with last prompt' do
      before do
        QuestionsVisit.delete_all
        @controller.session[:last_prompt] = [1,1,1,1,1]
        @controller.should_receive(:current_visit!).twice.and_return(Visit.first)
        Pairwise.stub!(:prompt).and_return([[1], [[1,2]], [['one','two']]])
      end

      it 'should set last prompt' do
        get :show, :id => 1
        vs = [assigns[:winner_id], assigns[:winner], assigns[:loser_id], assigns[:loser], assigns[:skip]]
        vs.length.should == vs.compact.length
      end
      
      it 'should set last prompt to nil' do
        get :show, :id => 1
        @controller.session[:last_prompt].should == nil
      end
    end
  end

  describe 'new' do
    it 'should not set without id' do
      @controller.should_not_receive(:set_pairwise_from_question_id)
      get :new
    end

    it 'should not set without prompt id' do
      @controller.should_not_receive(:set_pairwise_from_question_id)
      get :new, :id => 1
    end

    it 'should not set without id but with prompt id' do
      @controller.should_not_receive(:set_pairwise_from_question_id)
      get :new, :prompt_id => 1
    end

    describe 'with valid data' do
      before do
        Pairwise.stub!(:get_prompt).and_return([[1,2]])
        Pairwise.should_receive(:get_item).with(1).and_return('one')
        Pairwise.should_receive(:get_item).with(2).and_return('two')
      end

      it 'should set' do
        @controller.should_receive(:set_pairwise_from_question_id)
        get :new, :id => 1, :prompt_id => 1
      end

      it 'should set last prompt' do
        get :new, :id => 1, :prompt_id => 1
        @controller.session[:last_prompt].should_not == nil
      end

      it 'should add true if item is skip' do
        get :new, :id => 1, :prompt_id => 1
        @controller.session[:last_prompt].last.should == true
      end
        
      it 'should add false otherwise' do
        get :new, :id => 1, :prompt_id => 1, :item_id => 1
        @controller.session[:last_prompt].last.should == false
      end

      it 'should redirect' do
        get :new, :id => 1, :prompt_id => 1, :item_id => 1
        response.should be_redirect
      end
    end
  end

  describe 'map' do
    before do
      Pairwise.stub!(:get_question).and_return(1, 'test')
      Pairwise.stub!(:list_items).and_return([])
      Pairwise.stub!(:list_votes).and_return([])
    end

    it 'should set vars' do
      get :map, :question_id => 1
      vs = [assigns[:ip_percents], assigns[:label], assigns[:explain]]
      vs.length.should == vs.compact.length
    end
  end

  describe 'named' do
    fixtures :questions, :users

    describe 'with prompt fail' do
      it 'should redirect' do
        name = 'nameq3'
        get :named, :path => "#{name}"
        response.should be_redirect
      end

      it 'should not success' do
        name = 'NAMeq3'
        get :named, :path => "#{name}"
        response.should_not be_success
      end
    end

    describe 'with success' do
      before do
        @controller.stub!(:vars_for_question).and_return(true)
      end

      it 'should pick up name' do
        name = 'nameq3'
        get :named, :path => "#{name}"
        response.should_not be_redirect
      end

      it 'should pick up name by downcase' do
        name = 'NAMeq3'
        get :named, :path => "#{name}"
        response.should be_success
      end

      it 'should assign name' do
        name = 'nameq3'
        get :named, :path => "#{name}"
        assigns[:name].should == name
      end

      it 'should not pick up non name' do
        get :named, :path => '/ddddd'
        response.should redirect_to(root_path)
      end
    end
  end

  describe 'feedback' do
    fixtures :questions, :users

    before do
      Pairwise.stub!(:get_question).and_return([1, 'test'])
    end

    it 'should not submit on get' do
      get :feedback, :question_id => 1
      flash[:notice].should == nil
    end

    it 'should require qid' do
      post :feedback, :question_id => 1
      flash[:notice].should == nil
    end

    it 'should require feedback' do
      post :feedback, :question_id => 1
      flash[:notice].should == nil
    end

    it 'should require non blank feedback' do
      post :feedback, :feedback => '', :question_id => 1
      flash[:notice].should == nil
    end

    it 'should submit' do
      post :feedback, :feedback => 'a', :question_id => 1
      flash[:notice].should_not == nil
    end
  end
end