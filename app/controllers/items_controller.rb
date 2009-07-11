class ItemsController < ApplicationController
  before_filter :require_question_id_or_name, :except => :activate
  before_filter :second_nav, :only => [:index, :show, :newest, :search]

  def index
    @current_page = t('nav.view_results')
    @header_text = t('items.score')
    item_list_vars(Const::RANK_ALGO_ID, Const::ITEM_LIMIT)
  end

  def all
    @current_page = t('nav.view_results')
    @third_page = t('nav.all_ideas')
    @header_text = "#{t('items.score')} "
    item_list_vars(Const::RANK_ALGO_ID)
    @items_all = true
    render :index
  end

  def newest
    @current_page = t('nav.view_results')
    @third_page = t('nav.newest_ideas')
    @header_text = t('items.added_on')
    @items_newest = true
    item_list_vars(0)
    render :index
  end

  def show
    @id, @item, @added, @rank, @wins, @losses, @score = Pairwise.get_item(params[:id], Const::RANK_ALGO_ID)
    votes = Pairwise.list_votes(@question_id, @id, 100)
    @ip_percents = ip_percents(votes)
    @explain = t('items.map_explanation')
    @current_page = t('nav.view_idea')
  end

  def new
    @current_page = t('nav.add_an_idea')
  end

  def create
    item = HTML::FullSanitizer.new.sanitize(params[:item])
    if !item || item.blank? || item == t('vote.add_your_idea')
      flash[:v_error] = t('items.new.missing_value')
    elsif item.length > Const::MAX_ITEM_LENGTH
      flash[:v_error] = "#{t('items.new.too_long')} #{Const::MAX_ITEM_LENGTH}."
    else
      set_pairwise_from_question_id(@question_id)
      id = Pairwise.item(item, [@question_id], ip_address).first
      user = Question.first(:conditions => { :pairwise_id => @question_id }).user
      Mailer.deliver_add_item(t('items.item_added_to_question'), user, @question, @question_id, item, id)
      flash[:v_notice] = t('items.new.added_successfully')
    end
    @current_page = t('nav.add_an_idea')
    question = Question.first(:conditions => { :pairwise_id => @question_id })
    redirect_to named_url_for_question(question)
  end

  def search
    @current_page = t('nav.view_results')
    @third_page = t('nav.search_for_an_idea')
    if request.post? && @query = params[:query]
      @items = active_items(@question_id, @algo)
      @items.reject! { |el| (el[1] =~ /.*#{@query}.*/i).nil? }
    end
  end

  def score
    render :layout => 'blank'
  end

  def activate
    question_id, item_id = Base64.decode64(params[:id]).split('-')
    set_pairwise_from_question_id(question_id)
    Pairwise.update_item_state(item_id, true)
    item = Pairwise.get_item(item_id)[1]
    question = Question.first(:conditions => { :pairwise_id => question_id })
    flash[:notice] = "<span class=\"large-text\">#{t('items.new.activated')} \"<strong>#{item}</strong>\"</span>"
    redirect_to named_url_for_question(question)
  end

  private
    def count(arr)
      tmp = arr.first
      count = 0
      ret = arr.sort.inject([]) do |arr, el|
        if tmp == el
          count += 1
        else
          arr << (tmp << count)
          count = 0
          tmp = el
        end
        arr
      end
      tmp ? ret << (tmp << count) : ret
    end

    def locate(arr)
      arr.map do |ip|
        geo = GeoIP.location(ip)
        geo ? [geo[:latitude], geo[:longitude], geo[:city]] : nil
      end.compact
    end

    def item_list_vars(algo, limit = nil)
      @items = active_items(@question_id, algo, limit)
      @ip_percents = ip_percents(Pairwise.list_votes(@question_id, nil, 100), false)
      @label = t('items.total')
      @explain = t('questions.map_explanation')
    end
end
