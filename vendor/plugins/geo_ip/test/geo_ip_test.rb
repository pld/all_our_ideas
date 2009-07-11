require File.dirname(__FILE__) + '/test_helper.rb'

class GeoIPTest < Test::Unit::TestCase
  def test_should_set_database
    GeoIP.database(db)
    assert !GeoIP.db.nil?
  end

  def test_should_return_v
    GeoIP.database(db)
    v = Object.new
    assert_equal GeoIP.location('127.0.0.1', v), v
  end
private
  def db; '/opt/geoip/share/GeoIP/GeoLiteCity.dat' end
end
