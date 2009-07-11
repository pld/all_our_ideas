require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::ItemsController do
  it "should require set user" do
    get :index
    response.should be_redirect
  end

  describe 'with user' do
    fixtures :questions

    before do
      @controller.set_user('login', 'password')
      Pairwise.stub!(:list_questions).and_return([['1']])
    end

    describe 'index' do
      before do
        Pairwise.stub!(:list_items).and_return([])
      end
      
      it 'should set items' do
        get :index
        assigns[:items].should_not == nil
      end
    end

    describe 'state' do
      it 'should not set without id' do
        @controller.should_not_receive(:set_pairwise_user)
        get :state
      end

      it 'should set with id' do
        @controller.should_receive(:set_pairwise_user)
        get :state, :id => 1
      end

      it 'should redirect to users w/o qid' do
        get :state, :id => 1
        response.should redirect_to(users_path)
      end

      it 'should redirect to question w/qid' do
        get :state, :id => 1, :question_id => 1
        response.should redirect_to(question_path(1))
      end
    end

    describe 'new' do
      it 'should set questions' do
        get :new
        assigns[:questions].should_not == nil
      end

      it 'should set qid' do
        get :new, :question_id => 1
        assigns[:question_id].should == '1'
      end
    end

    describe 'create' do
      describe 'with invalid data' do
        it 'should not set w/o qid' do
          @controller.should_not_receive(:set_pairwise_user)
          get :create
        end

        it 'should not set w/o qid and w/ item' do
          @controller.should_not_receive(:set_pairwise_user)
          get :create, :item => 'item'
        end

        it 'should not set w/ qid and w/o item' do
          @controller.should_not_receive(:set_pairwise_user)
          get :create, :question => 1
        end

        it 'should not set w/ qid and w/ blank item' do
          @controller.should_not_receive(:set_pairwise_user)
          get :create, :question => 1, :item => ''
        end

        it 'should not set with item too long' do
          @controller.should_not_receive(:set_pairwise_user)
          get :create, :question => 1, :item => Array.new(Const::MAX_ITEM_LENGTH + 1).inject('') { |s,e| s += "a" }
        end

        it 'should not set with an item too long' do
          @controller.should_not_receive(:set_pairwise_user)
          get :create, :question => 1, :item => Array.new(Const::MAX_ITEM_LENGTH + 1).inject('') { |s,e| s += "a" } + "\nitem"
        end

        it 'should set flash error w/ qid and w/o item' do
          get :create, :question => 1
          flash[:error].should_not == nil
        end

        it 'should redirect' do
          get :create, :question => 1
          response.should be_redirect
        end
      end

      describe 'with valid data' do
        fixtures :users, :questions

        before do
          Pairwise.stub!(:voter).and_return([1])
        end
        
        it 'should set' do
          Pairwise.stub!(:item)
          @controller.should_receive(:set_pairwise_user)
          get :create, :question => 1, :item => 'item'
        end

        it 'should set flash notice' do
          get :create, :question => 1, :item => 'item'
          flash[:notice].should_not == nil
        end

        it 'should redirect to question if question active' do
          get :create, :question => 1, :item => 'item'
          response.should redirect_to(question_path(1))
        end

        it 'should call with split items' do
          ivar = "item\nitem2"
          Pairwise.should_receive(:item).with(ivar.split, [1], '0.0.0.0', true, 1)
          get :create, :question => 1, :item => ivar
        end

        it 'should reject blank lines' do
          ivar = "item\n\n\n\nitem2\n\nitem3"
          Pairwise.should_receive(:item).with(["item", "item2", "item3"], [1], '0.0.0.0', true, 1)
          get :create, :question => 1, :item => ivar
        end


        it 'should reject blank lines' do
          ivar = "\n\n\n\n"
          Pairwise.should_not_receive(:item)
          get :create, :question => 1, :item => ivar
        end

        it 'should sanitize items' do
          ivar = "item\n<a>item2</a>\n<a>item3</a>"
          Pairwise.should_receive(:item).with(['item', 'item2', 'item3'], [1], '0.0.0.0', true, 1)
          get :create, :question => 1, :item => ivar
        end
        it 'should flash active notice if question inactive' do
          get :create, :question => 2, :item => 'item'
          (flash[:notice] =~ /activate/).should_not == nil
        end

        it 'should redirect to list questions if question inactive' do
          get :create, :question => 2, :item => 'item'
          response.should redirect_to(questions_path)
        end
      end
    end
  end
end
