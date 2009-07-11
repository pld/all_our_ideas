class UsersController < ApplicationController
  before_filter :require_user_set, :only => :index
  before_filter :require_user_unset, :only => :new

  def index
    @questions = questions
    votes = Pairwise.list_votes(nil, nil, 100)
    @ip_percents = ip_percents(votes, false)
    @label = t('items.total')
    @explain = t('user.map_explanation')
  end

  def new
    @header = true
    if request.post?
       @user = User.new(params[:user])
       if @user.valid?
        Pairwise.server(PAIRWISE_PARAMS)
        if Pairwise.user(@user.email, @user.email, @user.password).first.to_i > 0
          # successfully created user
          set_user(@user.email, @user.password)
          @user.save
          redirect_to new_question_path
        else
          flash.now[:error] = t('error.pairwise_error')
        end
       end
    end
  end

  private
    def valid_signup(params)
      values = [params[:login], params[:email], params[:password], params[:password_confirmation]]
      values.any? { |el| el.nil? || el.empty? } || params[:password] != params[:password_confirmation] ? false : values
    end
end
