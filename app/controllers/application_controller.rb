# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include Systems::Visit
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  before_filter :fetch_visit
  before_filter :set_vars

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password, :password_confirmation

  def set_vars
    if user_set?
      @login = user_creds[:email]
    end
  end

  def reset_user
    session[:user] = nil
  end

  def set_user(email, password)
    session[:user] = { :email => email, :password => password, :encoded_pass => Base64.encode64(password) }
  end

  def user_set?
    user_creds && user_creds.values.all? { |el| !el.nil? && !el.to_s.empty? }
  end

  def require_user_set
    unless user_set?
      redirect_to root_path
      flash[:error] = t('error.please_login_to_access_this_resource')
    end
    @header = true
  end

  def require_user_unset
    if user_set?
      redirect_to root_path
      flash[:error] = t('error.you_already_have_an_account')
    end
  end

  def user_creds
    session[:user]
  end

  def questions(question_id = nil)
    question_id ? set_pairwise_from_question_id(question_id) : set_pairwise_user
    pairwise_qs = Pairwise.list_questions
    Question.all(
      :conditions => { :pairwise_id => pairwise_qs.transpose.first }
    ).inject([]) do |array, question|
      array << (pairwise_qs.assoc(question.pairwise_id.to_s) << question.active << question.id)
    end
  end

  def user_account?
    if user_set?
      !User.first(:conditions => { :email => user_creds[:email], :encoded_password => user_creds[:encoded_pass] }).nil?
    else
      false
    end
  end

  def current_user_id!
    if user_set?
      id = user_creds[:id]
      if id.nil?
        user = User.first(:conditions => { :email => user_creds[:email], :encoded_password => user_creds[:encoded_pass] })
        session[:user][:id] = user.id
      else
        id
      end
    end
  end

  def percentage(num, denom)
     denom.zero? ? "0%" : "#{(100 * (num.to_f / denom)).round}%"
  end

  def second_nav
    @second_nav = true
  end

  def named_url_for_question(question)
    "#{url_prefix}#{question.name}"
  end

  def parse_items(items)
    if items
      sanitizer = HTML::FullSanitizer.new
      items.split("\n").reject(&:empty?).map { |el| sanitizer.sanitize(el) }
    end
  end

  protected
    def url_prefix
      "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}/"
    end

    
    def active_items(question_id, algo = nil, limit = nil)
      items = Pairwise.list_items(question_id, algo, true)
      items = items.reject { |el| el[2].to_i.zero? }
      limit ? items.first(limit) : items
    end

    def set_pairwise_user(email = nil, pass = nil)
      pairwise_params = PAIRWISE_PARAMS.merge(:user => email || user_creds[:email], :pass => pass || user_creds[:password])
      Pairwise.server(pairwise_params)
    end

    def user_from_question_id(id)
      Question.first(:conditions => { :pairwise_id => id }).user
    end

    def set_pairwise_from_question_id(id)
      user = user_from_question_id(id)
      set_pairwise_user(user.email, user.decoded_password)
    end

    def ip_percents(votes, percent = true)
      ret = votes.inject({}) do |hash, vote|
        if ip = vote[3]
          unless hash[ip]
            geo = GeoIP.location(ip)
            if geo
              loc = geo[:city]
              loc = geo[:region] if loc && loc.empty?
              loc = geo[:county_name] if loc && loc.empty?
              hash[ip] = [geo[:latitude], geo[:longitude], loc, 0, 0]
            end
          end
          if hash[ip]
            col = vote.last.nil? ? 3 : 4
            hash[ip][col] += 1
          end
        end
        hash
      end
      ret.values.map { |el| el << (el.pop + el.pop) }
    end

    def fill_question
      set_pairwise_from_question_id(@question_id)
      @question_internal = Question.first(:conditions => { :pairwise_id => @question_id })
      @question_id, @question, @items_count, @votes_count = Pairwise.get_question(@question_id)
    end

    def require_question_id
      if (@question_id = params[:question_id]).nil?
        redirect_to root_path
        return
      end
    end

    def require_question_id_or_name
      @question_id = params[:question_id] || parse_question_id_from_name
      @question_id ? fill_question : redirect_to(root_path)
    end

    def parse_question_id_from_name
      @name = params[:name]
      @name = @name.is_a?(Array) ? @name.first.downcase : @name.downcase if @name
      @name && Question.first(:conditions => { :name => @name }).pairwise_id
    end
end