class VoteController < ApplicationController
  include Systems::Visit

#  before_filter CASClient::Frameworks::Rails::Filter
  before_filter :require_question_id_or_name, :only => [:index, :map, :feedback]
  before_filter :fill_question, :only => [:index, :map, :feedback]
  before_filter :second_nav, :only => [:index, :new, :map]
  
  def index
    @current_page = t('nav.view_results')
    @third_page = t('nav.recent_winners')
    votes = Pairwise.list_votes(@question_id, nil, 10)
    @responses = votes.inject([]) do |array, vote|
      item = vote.last
      winner = item ? [from_hash_or_get_item(item)] : []
      losers = Pairwise.get_prompt(vote[1]).last
      array << [winner, losers.map { |loser| from_hash_or_get_item(loser) } - winner]
    end
  end

  def show
    id = params[:id].to_i
    if id > 0
      @current_page = t('vote.cast_votes')
      @question_internal = Question.first(:conditions => { :pairwise_id => id, :active => true })
      vars_for_question(id)
    else
      redirect_to root_path
    end
  end

  def new
    # filter out bots
    unless looks_like_a_bot?
      id = params[:id].to_i
      item_id = params[:item_id]
      prompt_id = params[:prompt_id].to_i
      if id > 0 && prompt_id > 0
        set_pairwise_from_question_id(id)
        qv = QuestionsVisit.qv(id, current_visit.id)
        Pairwise.vote(prompt_id, item_id, qv.voter_id_ext, get_response_time, ip_address)
        items = Pairwise.get_prompt(prompt_id).last
        items = [items] << items.map { |p_id| Pairwise.get_item(p_id)[1] }
        if items.first.first == item_id
          session[:last_prompt] = [items.last.first, items.first.first, items.last.last, items.first.last]
        else
          session[:last_prompt] = [items.last.last, items.first.last, items.last.first, items.first.first]
        end
        item_id.to_i > 0 ? session[:last_prompt] << false : session[:last_prompt] << true
      end
      clear_prompt_for_question_visit(id)
    end
    params[:name] ? redirect_to("/#{params[:name]}") : redirect_to(vote_path(id))
  end

  def map
    votes = Pairwise.list_votes(@question_id, nil, 100)
    @ip_percents = ip_percents(votes, false)
    @current_page = t('nav.view_results')
    @third_page = t('nav.map_of_voters')
    @label = t('items.total')
    @explain = t('questions.map_explanation')
  end

  def named
    @name = params[:path]
    @name = @name.is_a?(Array) ? @name.first.downcase : @name.downcase
    unless @name && @question_internal = Question.first(:conditions => { :name => @name, :active => true })
      redirect_to(root_path)
    else
      if request.post? || params[:p] == '1'
        if @question_internal.id == Const::TOUR_DEMO_QUESTION_ID
          flash.now[:notice] = render_to_string(:partial => 'example_note')
        else
          flash.now[:notice] = render_to_string(:partial => 'new_question')
        end
      end
      @current_page = t('vote.cast_votes')
      vars_for_question(@question_internal.pairwise_id) && render(:show)
    end
  end

  def feedback
    if request.post? && params[:feedback] && !params[:feedback].blank?
      user = Question.first(:conditions => { :pairwise_id => @question_id }).user
      Mailer.deliver_feedback(t('feedback.submitted_feedback'), user, @question, params[:email], params[:feedback])
      flash[:notice] = t('feedback.successfully_sent')
    end
  end

  private
    def from_hash_or_get_item(id)
      @items ||= Pairwise.list_items(@question_id, nil, true).inject({}) do |hash, item|
        hash[item[0]] = item[0, 2]
        hash
      end
      @items[id] || (@items[id] = Pairwise.get_item(id)[0,2])
    end

    # To keep the client light and remove the need for Javascript response
    # time tracking is done on the server.  Here a time is stored in the
    # session, on vote the time is diffed and reset. Time is sent in
    # milliseconds.
    def get_response_time #:doc:
      ret = session[:prompt_time].nil? ? 0 : (1000 * (Time.now - session[:prompt_time])).round
      session[:prompt_time] = nil
      ret
    end

    def vars_for_question(id)
      set_pairwise_from_question_id(id)
      @question_id, @question, @items_count, @votes_count = Pairwise.get_question(id)
      prompt_for_question_visit(id)
      unless @prompt_id
        unless fetch_prompt_for_question_visit(id)
          flash[:error] = t('error.not_enough_items')
          redirect_to root_path
          return false
        end
        @winner, @winner_id, @loser, @loser_id, @skip = session[:last_prompt] unless session[:last_prompt].nil?
        session[:last_prompt] = nil
      end
      session[:prompt_time] = Time.now
    end

    def looks_like_a_bot?
      user_agent =~ /bot/i
    end
end
