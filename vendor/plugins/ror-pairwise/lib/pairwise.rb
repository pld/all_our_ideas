require 'net/http'

module Pairwise
  class << self
    include LibXML

    # The Base 64 encoded pairwise user and password.
    attr_reader :auth
    # The host as set by server.
    attr_reader :host
    # The protocol as set by server.
    attr_reader :protocol
    # The key for requests requiring credentials
    attr_reader :key

    # Set the pairwise server auth, host, and protocol values.
    # ==== Parameters
    # options:host::  the pairwise server.
    # options:user:: the pairwise user.
    # options:password:: the pairwise password for user.
    # options:protocol:: the internet protocol to use, probably HTTP or HTTPS.
    def server(options)
      @auth = Base64.encode64("#{options[:user]}:#{options[:pass]}")
      @host = options[:host]
      @protocol = options[:protocol]
      @key = options[:key] && Base64.encode64(options[:key])
    end

    # Create a user
    # ==== Return
    # Added user login.
    # ==== Parameters
    # login:: login of user
    # email:: email of user
    # password:: password of user
    def user(login, email, password)
      xml = xml_root("user")
      xml.root << (XML::Node.new("login") << login)
      xml.root << (XML::Node.new("email") << email)
      xml.root << (XML::Node.new("password") << Base64.encode64(password))

      send_and_process("users/add?key=#{key}", 'user', xml)
    end

    # Create a question.
    # ==== Return
    # Array of question external IDs.
    # ==== Parameters
    # data:: a single question string or an array of question strings.
    def question(data)
      xml = xml_root("questions")

      arrayed(data).each do |name|
        xml.root << (XML::Node.new("question") << name)
      end

      send_and_process('questions/add', 'questions/question', xml)
    end

    # Create an item for questions.
    # ==== Return
    # On success returns an array of item external IDs. Failure on passing
    # non-existent question ID.
    # ==== Parameters
    # data:: a single item data string or an array of item data strings.
    # question_ids:: an array of integers representing the external IDs of the questions the item is to be added to.
    # tracking:: data to store with the item.
    # active:: if exists it's are activate
    # voter_id:: if exists voter id is passed to pairwise.
    def item(data, question_ids, tracking = nil, active = nil, voter_id = nil)
      xml = xml_root("items")

      questions = question_ids.inject(XML::Node.new("questions")) do |doc, id|
        question = XML::Node.new("question")
        question["id"] = id.to_s
        doc << question
      end

      arrayed(data).each do |name|
        xml.root << (XML::Node.new("item") << (XML::Node.new("data") << name) << questions.copy(true))
      end
      path = 'items/add' + query_string(['tracking', 'active', 'voter_id'].zip([tracking, active, voter_id]))
      send_and_process(path, 'items/item', xml)
    end

    # Update an item's state.
    # ==== Return
    # On response returns true. Failure on incorrect item id.
    # ==== Parameters
    # item_id:: the external ID of the items whose state to set.
    # state:: state will be set to 'activated' if state is true.  Otherwise
    # state will be set to 'suspended'.
    def update_item_state(item_id, state)
      !send_pairwise_request("items/#{item_id}/#{state ? 'activate' : 'suspend'}", nil, 'Get').nil?
    end

    # Create voters with given features.  Each can pass a single hash of features
    # to create a single voter or an array of hashes to create multiple voters.
    # ==== Return
    # On sucess returns the voter external ID.
    # ==== Parameters
    # features:: a hash of name to value pairs for the voter's features.
    def voter(features = {})
      xml =  arrayed(features).inject(xml_root("voters").root) do |voters, hash|
        voter = XML::Node.new("voter")
        features = XML::Node.new("features")
        hash.each do |name, value|
          feature = XML::Node.new("feature") << value
          feature["name"] = name.to_s
          features << feature
        end
        voters << (voter << features)
      end
      send_and_process('voters/add', 'voters/voter', xml)
    end

    # Update the state of voter feature name to value.
    # ==== Retturn
    # On success returns voter external ID.
    # ==== Parameters
    # voter_id:: the external voter ID.
    # name:: the feature to set.
    # value:: the value to set the feature to.
    # ==== Failure
    # * on incorrect voter ID.
    def update_voter_state(voter_id, name, value)
      send_and_process("voters/set/#{voter_id}?#{name}=#{value}", 'voter')
    end

    # Create n prompts for question and voter.  Can restrict to items and specify number of items
    # expected in returned prompt.
    # ==== Return
    # Array with each member a prompt external id followed by an array of item
    # external IDs for that prompt.  If data is passed the external ids are
    # followed by an array of item data.
    # ==== Parameters
    # question_id:: the question to create the prompt for.
    # voter_id:: the voter to create the prompt for.  A value of 0 is the anonymous voter.
    # n:: the number of prompts to create, default 1.
    # item_ids:: an array of items external ids to limit the items in the created prompt to, default nil.
    # num_items:: the number of items per prompt, default 2.
    # data:: retrieve data as well
    # ==== Failure
    # * on question_id not belonging to pairwise user or not existing
    # * on voter_id not belonging to pairwise user or not existing
    def prompt(question_id, voter_id, n = 1, prime = false, num_items = 2, data = nil)
      res = "prompts/create/#{question_id}/#{voter_id || 0}/#{n}"
      res += "/1" if prime
      res += "?data=1" unless data.nil?
      res = send_pairwise_request(res, nil, 'Get')

      # process response
      if res
        prompt_ids = fetch_xml_attr('prompts/prompt', res)
        item_ids = fetch_xml_attr('prompts/prompt/items/item', res)
        ret = [prompt_ids, prompt_ids.map { |id| item_ids.slice!(0, num_items) }]
        if data
          item_content = XML::Parser.content(res.body, 'prompts/prompt/items/item')
          ret << prompt_ids.map { |id| item_content.slice!(0, num_items) }
        end
        ret
      end
    end

    # Tell pairwise this prompt has been viewed so stats can be updated
    # ==== Parameters
    # id:: the prompt external ID.
    def view(id)
      send_pairwise_request("prompts/view/#{id}")
    end

    # Create a vote on a prompt for an item or a skip if nil.  Can be cast for
    # a voter or the
    # anonymous voter and a response time can be sent.
    # ==== Return
    # Array of vote external IDs.
    # ==== Parameters
    # prompt_id:: the prompt external id to record a vote for.
    # item_id:: the item_id to record the vote for.  If item_id is nil or false
    # a skip vote is sent.
    # voter_id:: the voter external ID to record the vote for.  Defaults to the
    # anonymous voter, a value of 0.
    # response_time:: the response time of the vote, default 0.
    # tracking:: additional data to store with pairwise.
    # ==== Failure
    # * on non-existent prompt_id or prompt_id not belonging to pairwise user.
    # * on item_id not belonging to prompt.
    # * on voter_id not beloning to current user if voter_id is greater than 0.
    def vote(prompt_id, item_id = nil, voter_id = 0, response_time = 0, tracking = nil)
      path = "votes/add/#{prompt_id}/#{voter_id || 0}/#{response_time}"
      path += "/#{item_id}" if item_id
      path += "?tracking=#{tracking}"  if tracking
      send_and_process(path, 'vote')
    end

    # List items.  Can pass a question and rank algorithm ID.  List items
    # for question according to rank algorithm.
    # ==== Return
    # Array each element being an item external ID followed by a rank value.
    # ==== Parameters
    # question_id:: the question external ID of the question's items to
    # restrict the list to or nil for all questions, default nil.
    # rank_algorithm_id:: the rank algorithm to user in listing, default nil.
    # limit:: the number of items to return.
    def list_items(question_id = nil, rank_algorithm_id = nil, data = nil, limit = nil)
      path = "items/list/#{question_id.to_i}/#{rank_algorithm_id.to_i}"
      path += "/#{limit}" unless limit.nil?
      path += "?data=1" unless data.nil?
      res = send_pairwise_request(path)
      if res
        [
          fetch_xml_attr('items/item', res),
          XML::Parser.content(res.body, 'items/item'),
          fetch_xml_attr('items/item', res, 'active'),
          fetch_xml_attr('items/item', res, 'rank'),
          fetch_xml_attr('items/item', res, 'wins'),
          fetch_xml_attr('items/item', res, 'losses'),
          fetch_xml_attr('items/item', res, 'added'),
          fetch_xml_attr('items/item', res, 'ratings'),
          fetch_xml_attr('items/item', res, 'skips'),
          fetch_xml_attr('items/item', res, 'score'),
        ].transpose
      end
    end

    # List questions.
    # ==== Return
    # Array each element is a question as [id, text].
    def list_questions
      res = send_pairwise_request("questions/list")
      if res
        fetch_xml_attr('questions/question', res).zip(XML::Parser.content(res.body, 'questions/question'))
      end
    end

    # List votes.  Can pass a question ID and optional item IDs.  List vote
    # for question and item.
    # ==== Return
    # Array each element being a vote external ID followed by prompt ID,
    # voter ID, and array of IDs of items that were voted for.
    # ==== Parameters
    # question_id:: the question external ID of the question's items to
    # restrict the list to or nil for all questions, default nil.
    # item_id:: restrict votes to this item ID, default nil.
    # limit:: limit to retrieve this many votes
    def list_votes(question_id = nil, item_id = nil, limit = nil)
      path = "votes/list"
      path += "/#{question_id}" if question_id
      path += "/#{item_id}" if item_id
      path += "?limit=#{limit}" if limit
      res = send_pairwise_request(path)
      if res
        [
          fetch_xml_attr('votes/vote', res),
          fetch_xml_attr('votes/vote/prompt', res, 'id'),
          fetch_xml_attr('votes/vote/voter', res, 'id'),
          fetch_xml_attr('votes/vote', res, 'tracking'),
          fetch_xml_attr('votes/vote', res, 'response_time'),
          XML::Parser.parse_with_nils(res.body, 'votes/vote/items', 'item')
        ].transpose
      end
    end

    # Retrieve question
    # ==== Return
    # Array of question id, text, number of items, number of votes
    # ==== Parameters
    # id:: the question ID
    def get_question(id)
      res = send_pairwise_request("questions/#{id}")
      if res
        [
          id,
          XML::Parser.content(res.body, 'question').first,
          fetch_xml_attr('question', res, 'items').first,
          fetch_xml_attr('question', res, 'votes').first,
          fetch_xml_attr('question', res, 'active_and_inactive_items').first,
        ]
      end
    end

    # Retrieve an item
    # ==== Return
    # Array of item id, text, added date, rank, wins, losses, added, ratings,
    # skips.
    # ==== Parameters
    # id:: the item ID
    def get_item(id, rank_algorithm = nil)
      path = "items/#{id}"
      path += "?rank_algorithm=#{rank_algorithm}" if rank_algorithm
      res = send_pairwise_request(path)
      if res
        [
          id,
          XML::Parser.content(res.body, 'item/data').first,
          fetch_xml_attr('item', res, 'added').first,
          fetch_xml_attr('item/questions/question', res, 'rank').first,
          fetch_xml_attr('item/questions/question', res, 'wins').first,
          fetch_xml_attr('item/questions/question', res, 'losses').first,
          fetch_xml_attr('item/questions/question', res, 'score').first,
        ]
      end
    end

    # Retrieve a prompt
    # ==== Return
    # Array of prompt id, question, array items for prompt
    # ==== Parameters
    # id:: the prompt ID
    def get_prompt(id)
      res = send_pairwise_request("prompts/#{id}")
      if res
        [
          id,
          fetch_xml_attr('prompt/question', res).first,
          fetch_xml_attr('prompt/items/item', res)
        ]
      end
    end

private
    # ==== Return
    # Response from the pairwise path parsed with the res_path.
    # ==== Parameters
    # path:: where to send the pairwise request to.
    # res_path:: the parse path for the xml.
    # xml:: the data to send to pairwise, default nil.
    def send_and_process(path, res_path, xml = nil) # :doc:
      # send XML
      res = send_pairwise_request(path, xml)
      # process response
      fetch_xml_attr(res_path, res) if res
    end

    # ==== Parameters
    # path:: where to send the pairwise request to.
    # xml:: the post body to send.  If xml is nil and method is nil (see below)
    # a get request is sent.  Default nil.
    # method:: type of request to send.  If method is nil request type is
    # determined by the value of value of xml.
    def send_pairwise_request(path, xml = nil, method = nil) # :doc:
      url = URI.parse("#{protocol}://#{host}/#{path}")
      headers = {
        'Content-Type' => 'text/xml',
        'Authorization' => "Basic #{auth}"
      }
      res = Net::HTTP.new(url.host, url.port)
      res.use_ssl = true if url.port == Net::HTTP.https_default_port
      # if xml is nil assum GET, otherwise POST
      res = res.request(('Net::HTTP::' + (method || (xml.nil? ? 'Get' : 'Post'))).constantize.new(url.request_uri, headers), xml && xml.to_s)
      res.is_a?(Net::HTTPSuccess) ? res : nil
    end

    # ==== Parameters
    # xml:: an HTTP response.
    # path:: the path to search in xml.
    # attribute:: the attribute to return for each element in the search path.
    def fetch_xml_attr(path, xml, attribute = "id") # :doc:
      XML::Parser.parse(xml.body, "/pairwise/#{path}", attribute)
    end

    # wrap in an array if not an array.
    # ==== Parameters
    # object:: object or array.
    def arrayed(object) # :doc:
      (object.is_a?(Array) ? object : [object])
    end

    # creates an XML document and sets the root value to string.
    # ==== Parameters
    # string:: the root value of a new XML document.
    def xml_root(string) # :doc:
      xml = XML::Document.new
      xml.root = XML::Node.new(string)
      xml
    end

    def query_string(params)
      str = params.inject('') do |str, el|
        name, value = el
        value ? str + "#{name}=#{value}&" : str
      end
      str.empty? ? str : '?' + str.chop
    end
  end
end