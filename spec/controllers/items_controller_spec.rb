require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ItemsController do
  fixtures :questions, :users
  
  before do
    Pairwise.stub!(:voter).and_return([1])
    Pairwise.stub!(:get_question).and_return([1, 'test'])
  end

  describe 'index' do
    before do
      Pairwise.stub!(:list_votes).and_return([])
      Pairwise.stub!(:list_items).and_return([])
    end
    
    it 'redirects if no question_id' do
      get :index
      response.should be_redirect
    end
    
    it 'should set items' do
      get :index, :question_id => 1
      assigns[:items].should_not == nil
    end
  end

  describe 'show' do
    before do
      Pairwise.stub!(:get_item).and_return([1, 'item', 'date', 1, 1, 0, 100])
      Pairwise.stub!(:list_votes).and_return([["143758", "591539", "0", "127.0.0.1", "5400", "3360"], ["143760", "591541", "0", "127.0.0.1", "4201", nil], ["143762", "591543", "0", "127.0.0.1", "2319", nil], ["143763", "591544", "0", "127.0.0.1", "3235", nil], ["143764", "591545", "0", "127.0.0.1", "12552", nil]])
    end

    it 'redirects if no question_id' do
      get :show
      response.should be_redirect
    end

    it 'should set vars' do
      get :show, :question_id => 1
      vs = [assigns[:id], assigns[:item], assigns[:added], assigns[:rank], assigns[:wins], assigns[:losses]]
      vs.length.should == vs.compact.length
    end

    it 'should set percent' do
      get :show, :question_id => 1
      assigns[:score].should == 100
    end

    it 'should set ip_percents' do
      get :show, :question_id => 1
      assigns[:ip_percents].should_not == nil
    end

    it 'should set explain' do
      get :show, :question_id => 1
      assigns[:explain].should_not == nil
    end
  end

  describe 'new' do
    it 'redirects if no question_id' do
      get :new
      response.should be_redirect
    end

    it 'renders' do
      get :new, :question_id => 1
      response.should_not be_redirect
    end
  end

  describe 'create' do
    describe 'with invalid data' do
      it 'redirects if no question_id' do
        get :create
        response.should be_redirect
      end

      it 'assigns flash error if no item' do
        get :create, :question_id => 1
        flash[:v_error].should_not == nil
      end

      it 'assigns flash error if blank item' do
        get :create, :question_id => 1, :item => ''
        flash[:v_error].should_not == nil
      end

      it 'assigns flash error if too long item' do
        get :create, :question_id => 1, :item => Array.new(Const::MAX_ITEM_LENGTH + 1).inject('') { |s,e| s += "a" }
        flash[:v_error].should_not == nil
      end

      it 'redirects if no item' do
        get :create, :question_id => 1
        response.should be_redirect
      end
    end

    describe 'with valid item' do
      before do
      end

      it 'should set flash notice' do
        Pairwise.stub!(:item).and_return([1])
        get :create, :question_id => 1, :item => 1
        flash[:v_notice].should_not == nil
      end

      it 'redirects' do
        Pairwise.stub!(:item).and_return([1])
        get :create, :question_id => 1, :item => 1
        response.should be_redirect
      end

      it 'sanitizes' do
        Pairwise.should_receive(:item).with('ll', [1], '0.0.0.0').and_return([1])
        get :create, :question_id => 1, :item => '<a>ll</a>'
      end
    end
  end

  describe 'search' do
    before do
      Pairwise.stub!(:list_items).and_return([])
    end

    it 'redirects if no question id' do
      get :search
      response.should be_redirect
    end

    it 'no set if no post' do
      get :search, :question_id => 1
      assigns[:items].should == nil
    end

    it 'no set if no query' do
      post :search, :question_id => 1
      assigns[:items].should == nil
    end

    it 'sets items' do
      post :search, :question_id => 1, :query => 'q'
      assigns[:items].should_not == nil
    end
  end

  describe 'activate' do
    before do
      @question_id = 1
      @item_id = '4454'
      @code = Base64.encode64("#{@question_id}-#{@item_id}")
      Pairwise.should_receive(:get_item).with(@item_id).and_return([1,'item'])
    end

    it 'should activate item with code' do
      Pairwise.should_receive(:update_item_state).with(@item_id, true)
      get :activate, :id => @code
    end

    it 'should flash with item' do
      get :activate, :id => @code
      (flash[:notice] =~ /item/).should_not == nil
    end

    it 'should redirect' do
      get :activate, :id => @code
      response.should be_redirect
    end
  end
end
