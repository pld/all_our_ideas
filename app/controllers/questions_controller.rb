require 'fastercsv'

class QuestionsController < ApplicationController
  before_filter :require_user_set

  def index
    @questions = questions
  end

  def new
    @question = Question.new(:question_text => t('questions.new.step1_exp'), :question_ideas => t('questions.new.step3_exp'))
    question = Question.find(Const::TOUR_DEMO_QUESTION_ID)
    @url1 = named_url_for_question(question)
  end

  def create
    set_pairwise_user
    @question = Question.new(params[:question])
    @question.name = @question.name == t('questions.new.step2_exp') ? nil : @question.name && @question.name.downcase
    @question.question_text = @question.question_text == t('questions.new.step1_exp') ? nil : HTML::FullSanitizer.new.sanitize(@question.question_text)
    ideas = @question.question_ideas = @question.question_ideas == t('questions.new.step3_exp') ? nil : @question.question_ideas
    ideas = parse_items(ideas)
    @question.valid?
    if ideas && ideas.any? { |i| i.length > Const::MAX_ITEM_LENGTH }
      @question.errors.add('question_ideas', "#{t('items.new.too_long')} #{Const::MAX_ITEM_LENGTH}.")
    end
    if @question.errors.empty?
      id = Pairwise.question(@question.question_text).first
      @question.update_attributes(
        :user_id => current_user_id!,
        :pairwise_id => id,
        :active => true
      )
      @question.question_ideas = parse_items(@question.question_ideas)
      unless @question.question_ideas.nil? || @question.question_ideas.empty?
        user = user_from_question_id(id)
        user.voter_id!
        set_pairwise_user(user.email, user.decoded_password)
        Pairwise.item(@question.question_ideas, [id], ip_address, true, user.voter_id)
      end
      redirect_to named_url_for_question(@question) + '?p=1'
    else
      render :new
      @question.question_ideas = ideas
    end
  end

  def show
    id = params[:id]
    if user_owns_id?(id)
      @question_internal = Question.find(id)
      id = @question_internal.pairwise_id
      set_pairwise_from_question_id(id)
      @id, @question, @items_count, @votes_count, all_items = Pairwise.get_question(id)
      @items = all_items.to_i > 0 ? Pairwise.list_items(@id, nil, true) : []
      @items = @items.sort_by { |el| el[2] }.reverse
      votes = Pairwise.list_votes(id, nil, 100)
      @ip_percents = ip_percents(votes, false)
      @label = t('items.total')
      @explain = t('questions.map_explanation')
      @named_url = named_url_for_question(@question_internal)
    else
      reset_user
      flash[:error] = t('error.permission_question')
      redirect_to login_path
    end
  end

  def edit
    id = params[:id]
    if user_owns_id?(id)
      @question_internal = Question.find(id)
      id = @question_internal.pairwise_id
      set_pairwise_from_question_id(id)
      @id, @question, @items_count, @votes_count, all_items = Pairwise.get_question(id)
    else
      flash[:error] = t('error.permission_question')
      redirect_to root_path
    end
  end

  def update
    id = params[:id]
    if user_owns_id?(id)
      question = Question.find(id)
      question.name = params[:question] && params[:question][:name] && params[:question][:name].downcase
      if question.save
        flash[:notice] = t('questions.short_url_success')
        redirect_to question_path(question.id)
      else
        @question_internal = question.reload
        id = @question_internal.pairwise_id
        set_pairwise_from_question_id(id)
        @id, @question, @items_count, @votes_count, all_items = Pairwise.get_question(id)
        render :edit
      end
    else
      flash[:error] = t('error.permission_question')
      redirect_to root_path
    end
  end

  def state
    id = params[:id]
    if user_owns_id?(id)
      question = Question.find(id)
      question.update_attribute(:active, params[:active])
      url_name = "#{url_prefix}#{question.name}"
      flash[:notice] = "#{t('questions.activate_message')} '<a href=\"#{url_name}\">#{url_name}</a>' #{t('questions.activate_message_2')}"  if question.active
      redirect_to questions_path
    else
      flash[:error] = t('error.permission_question')
      redirect_to users_path
    end
  end

  def export
    question_id = params[:id]
    items = active_items(question_id, 2)
    outfile = "question_#{question_id}_items_" + Time.now.strftime("%m-%d-%Y") + ".csv"
    csv_data = FasterCSV.generate do |csv|
      csv << [
      "Item ID",
      "Item Name",
      "Active",
      "Elo Score",
      "Ratings",
      "Wins",
      "Losses",
      "Skips",
      "Date Added"
      ]
      for id, item, active, rank, wins, losses, added, ratings, skips in items do
        csv << [
        id,
        item,
        active,
        rank,
        ratings,
        wins,
        losses,
        skips,
        added
        ]
      end
    end

    send_data(csv_data,
      :type => 'text/csv; charset=iso-8859-1; header=present',
      :disposition => "attachment; filename=#{outfile}"
    )
    flash[:notice] = t('questions.export_complete')
  end

  private
    def user_owns_id?(id)
      id = id.to_i
      id > 0 && user_set? && User.find(current_user_id!).question_ids.include?(id)
    end
end
