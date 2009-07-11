require File.dirname(__FILE__) + '/test_helper.rb'

class PairwiseTest < Test::Unit::TestCase
  
  def test_should_create_pairwise_from_options
    setup
    assert_equal Pairwise.auth, Base64.b64encode("#{options[:user]}:#{options[:pass]}")
    assert_equal Pairwise.host, options[:host]
    assert_equal Pairwise.protocol, options[:protocol]
  end

  def test_should_create_single_question
    setup
    p = Pairwise.question("data")
    assert_equal p.length, 1
    assert p.first.to_i > 0
  end

  def test_should_create_many_questions
    setup
    p = Pairwise.question(["data", "data2"])
    assert_equal p.compact.length, 2
  end

  def test_should_create_single_item
    setup
    p = Pairwise.item("data", create_questions)
    assert_equal p.length, 1
    assert p.first.to_i > 0
  end

  def test_should_create_single_active_item
    setup
    p = Pairwise.item("data", create_questions, nil, true)
    assert_equal p.length, 1
    assert p.first.to_i > 0
  end

  def test_should_create_many_items
    setup
    p = Pairwise.item(["data", "data2"], create_questions)
    assert_equal p.compact.length, 2
  end

  def test_should_create_single_voter
    setup
    p = Pairwise.voter({})
    assert p.first.to_i > 0
  end

  def test_should_create_many_voters
    setup
    p = Pairwise.voter([{ :gender => 1, :age => 3 }, { :gender => 0, :age => 18 }])
    assert_equal p.compact.length, 2
  end

  def test_should_set_voter_state
    setup
    voter = create_voter(:gender => 1).first
    v = Pairwise.update_voter_state(voter, 'gender', 2).first
    v.to_i > 0
  end

  def test_update_item_state
    qs = create_questions
    is = create_items(qs, true)
  end

  def test_should_create_single_prompt
    qs = create_questions
    is = create_items(qs, true)
    p = Pairwise.prompt(qs.first, create_voter.first)
    assert p.first.first.to_i > 0
    p.last.flatten.each { |item| assert is.include?(item.to_s) }
  end

  def test_should_create_multiple_prompts
    qs = create_questions
    is = create_items(qs, true)
    p = Pairwise.prompt(qs.first, create_voter.first, 4)
    p.first.map { |prompt| assert prompt.to_i > 0 }
    p.last.flatten { |item| assert is.include?(item.to_s) }
  end

  def test_should_create_multiple_prompts_for_items
    qs = create_questions
    create_items(qs, true)
    is = create_items(qs, true)
    p = Pairwise.prompt(qs.first, create_voter.first, 4, is.join(','))
    p.first.each { |prompt| assert prompt.to_i > 0 }
    p.last.flatten { |item| assert is.include?(item.to_s) }
  end

  def test_should_vote_on_prompt_with_anon_voter_without_response_time
    qs = create_questions
    is = create_items(qs, true)
    ps = Pairwise.prompt(qs.first, create_voter.first, 4, 0)
    v = Pairwise.vote(ps.first.first, ps.last.flatten.first, 0)
    assert v.first.to_i > 0
  end

  def test_should_vote_on_prompt_with_voter_without_response_time
    qs = create_questions
    is = create_items(qs, true)
    voter = create_voter.first
    ps = Pairwise.prompt(qs.first, voter, 4, 0)
    v = Pairwise.vote(ps.first.first, ps.last.flatten.first, voter)
    assert v.first.to_i > 0
  end

  def test_should_vote_on_prompt_with_voter_with_response_time
    qs = create_questions
    is = create_items(qs, true)
    voter = create_voter.first
    ps = Pairwise.prompt(qs.first, voter, 4, 0)
    v = Pairwise.vote(ps.first.first, ps.last.flatten.first, voter, 150)
    assert v.first.to_i > 0
  end

  def test_should_list_items_without_question_without_rank_algo
    qs = create_questions
    is = create_items(qs, true)
    r = Pairwise.list_items
    assert !r.empty?
  end

  def test_should_list_questions
    qs = create_questions
    r = Pairwise.list_questions
    assert !r.empty?
  end

private
  def setup
    Pairwise.server(options)
  end

  def options
    {
      :user => 'test',
      :pass => 'tester',
      :host => 'localhost:3000',
      :protocol => 'http'
    }
  end

  def create_questions
    setup
    Pairwise.question(["data", "data2"])
  end

  def create_items(questions, active = false)
    items = Pairwise.item(["data", "data2"], questions)
    items.each { |item| Pairwise.update_item_state(item, true) } if active
    items
  end

  def create_voter(params = {})
    Pairwise.voter(params)
  end
end
