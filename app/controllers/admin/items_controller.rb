class Admin::ItemsController < Admin::BaseController

  def index
    set_pairwise_user
    @items = Pairwise.list_items(nil, nil, true)
  end

  def state
    id = params[:id].to_i
    if id > 0
      set_pairwise_user
      Pairwise.update_item_state(id, params[:active].to_i.zero? ? true : false)
    end
    question_id = params[:question_id]
    question_id.nil? ? redirect_to(users_path) : redirect_to(question_path(question_id))
  end

  def new
    @question_id ||= params[:question_id]
    @questions = questions
  end

  def create
    id = params[:question].to_i
    items = parse_items(params[:item])
    if id == 0 || items.nil? || items.empty?
      flash[:error] = t('error.missing_value')
    elsif items.any? { |i| i.length > Const::MAX_ITEM_LENGTH }
      flash[:error] = "#{t('items.new.too_long')} #{Const::MAX_ITEM_LENGTH}."
    else
      user = user_from_question_id(id)
      user.voter_id!
      set_pairwise_user(user.email, user.decoded_password)
      Pairwise.item(items, [id], ip_address, true, user.voter_id)
      @question = Question.first(:conditions => { :pairwise_id => id })
      if @question.active
        flash[:notice] = t('items.new.added_successfully')
        redirect_to question_path(@question.id)
      else
        flash[:notice] = t('items.new.success_activate')
        redirect_to questions_path
      end
    end
    redirect_to new_admin_item_path(:question_id => id) if @question.nil?
  end
end
