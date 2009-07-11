module Systems::Visit
  def active_visit=(visit)
    session[:visit_id] = visit.id
    session[:visit_ip_country_code] = visit.ip_country_code
  end

  def current_visit_id
    session[:visit_id]
  end

  def current_visit_id!
    session[:visit_id] || create_visit.id
  end

  def current_visit_ip_country_code
    session[:visit_ip_country_code]
  end

  def exp_locale
    session[:exp_locale]
  end

  def current_visit
    current_visit_id && ::Visit.find(current_visit_id)
  end

  def current_visit!
    (current_visit_id && ::Visit.find(current_visit_id)) || create_visit
  end

  # time out visit if updated_at + const > now
  def fresh_visit?(visit = nil)
    visit ||= current_visit
    visit && visit.updated_at + Const::VISIT_STALE_AFTER > Time.now
  end

  def prompt_for_question_visit(qid)
    visit = current_visit!
    qv = ::QuestionsVisit.qv(qid, visit.id)
    if qv && @prompt_id = qv.prompt_id_ext
      @item_ids = Pairwise.get_prompt(@prompt_id).last
      @item_data = @item_ids.map { |id| Pairwise.get_item(id)[1] }
    end
  end

  def clear_prompt_for_question_visit(qid)
    visit = current_visit
    qv = ::QuestionsVisit.qv(qid, visit.id)
    qv.update_attribute(:prompt_id_ext, nil) if qv
  end

  def fetch_prompt_for_question_visit(qid)
    visit = current_visit!
    set_pairwise_from_question_id(qid)
    voter_id_ext = Pairwise.voter(:ip_address => ip_address).first
    qv = ::QuestionsVisit.qv(qid, visit.id) || ::QuestionsVisit.create!(
      :question_id => qid,
      :visit_id => visit.id,
      :voter_id_ext => voter_id_ext
    )
    @prompt_id, @item_ids, @item_data = Pairwise.prompt(qid, qv.voter_id_ext, 1, false, 2, true)
    return false if @prompt_id.nil?
    @prompt_id = @prompt_id.first
    qv.update_attribute(:prompt_id_ext, @prompt_id)
    @item_ids = @item_ids.first
    @item_data = @item_data.first
  end

  def fetch_visit
    unless current_visit
      visit = ::Visit.first(:conditions => {
        :ip_address => ip_address,
        :user_agent => user_agent,
        :active => true
      })
      if visit && !fresh_visit?(visit)
        visit.update_attribute(:active, false)
        visit = nil
      end
      visit ? self.active_visit = visit : create_visit
    end
  end

  def create_visit(locale = false)
    ip = ip_address
    visit = ::Visit.new do |v|
      v.locale = locale if locale
      v.ip_address = ip
      v.host = request.env['HTTP_HOST']
      v.user_agent = request.env['HTTP_USER_AGENT']
      v.referrer = request.env['HTTP_REFERER']
      v.request_uri = request.env['REQUEST_URI']
    end
    visit = GeoIP.location(ip, visit)
    visit.save!
    self.active_visit = visit
    visit
  end

  def ip_address
    request.env['HTTP_X_REAL_IP'] || request.env['REMOTE_ADDR']
  end

  def user_agent
    request.env['HTTP_USER_AGENT']
  end
end