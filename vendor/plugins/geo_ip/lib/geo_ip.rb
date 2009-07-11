module GeoIP
  class << self
    # The GeoIPCity database.
    attr_reader :db

    # Set the GeoIPCity database.
    #
    # loc:: a string to the filesystem database location.
    def database(loc)
      @db = GeoIPCity::Database.new(loc, :filesystem)
    end

    # Fetch location information from database and fill specific attributes of object.
    #
    # ip:: the IP address to be parsed.
    #
    # v:: the object to call attributes on
    def location(ip, v = nil)
      r = db.look_up(ip)
      return v if r.nil?
      if v
        v.ip_latitude = r[:latitude]
        v.ip_longitude = r[:longitude]
        v.ip_country_code = r[:country_code]
        v.ip_country_name = r[:country_name]
        v.ip_city = r[:city]
        v.ip_dma_code = r[:dma_code]
        v.ip_area_code = r[:area_code]
        v.ip_region = r[:region]
        v
      else
        r
      end
    end
  end
end