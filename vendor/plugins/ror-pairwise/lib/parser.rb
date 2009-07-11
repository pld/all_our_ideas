class LibXML::XML::Parser
  class << self
    # ==== Return
    # Array of elements from XML parsed by retrieving attribute value
    # for each element in path of XML.
    # ==== Params
    # string:: the XML to parse.
    # path:: the path to find in the XML.
    # attribute:: the attribute to request per element of the XML.
    def parse(string, path, attribute)
      string(string).parse.find(path).inject([]) do |arr, el|
        arr << el.attributes[attribute]
      end
    end

    # ==== Return
    # Array of elements from XML parsed by retrieving attribute value
    # for each element in path of XML taking care to return nils for values
    # that don't have the inner path but do have the outer path.  Default case
    # this would be ignore resulting in a shorter array.
    # ==== Params
    # string:: the XML to parse.
    # path:: the path to find in the XML.
    # inner_path:: the inner path to find in the XML.
    # attribute:: the attribute to request per element of the XML.
    def parse_with_nils(string, path, inner_path, attribute = 'id')
      string(string).parse.find(path).inject([]) do |arr, el|
        inner = el.find(inner_path).first
        arr << (inner ? inner.attributes[attribute] : nil)
      end
    end

    # ==== Return
    # Array of elements from XML parseed by retrieving each elements content.
    # ==== Params
    # string:: the XML to parse.
    # path:: the path to find in the XML.
    def content(string, path)
      string(string).parse.find(path).inject([]) do |arr, el|
        arr << el.content.strip
      end
    end
  end
end