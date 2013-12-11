require 'addressable/uri'
require 'rest-client'
require 'json'
require 'nokogiri'

class Location
  attr_accessor :lat, :long

  EARTH_RADIUS = 3959
  RADIANS_CONVERT = 0.0174

  def initialize(lat, long)
    @lat = lat
    @long = long
  end

  def self.bird_distance(loc1, loc2)
    dlon = loc2.long - loc1.long
    dlat = loc2.lat - loc1.lat
  
    #formula from http://en.wikipedia.org/wiki/Haversine_formula
    2 * EARTH_RADIUS * Math.asin(Math.sqrt(Math.sin(((loc2.lat - loc1.lat) * RADIANS_CONVERT)/2.0)**2 + 
      Math.cos(loc1.lat * RADIANS_CONVERT)*Math.cos(loc2.lat * RADIANS_CONVERT)*Math.sin(((loc2.long - loc1.long) * RADIANS_CONVERT)/2.0)**2))
  end

  def self.driving_distance(loc1, loc2)
    origin = "#{loc1.lat},#{loc1.long}"
    destination = "#{loc2.lat},#{loc2.long}"

    web_address = Addressable::URI.new(
      :scheme => "https",
      :host => "maps.googleapis.com",
      :path => "maps/api/directions/json",
      :query_values => { origin: origin, destination: destination,
                          sensor: false }
      ).to_s

    directions = JSON.parse(RestClient.get(web_address))
   
    str_dist = directions["routes"][0]["legs"][0]["distance"]["text"]

    Location.change_to_miles(str_dist)
  end

  def self.change_to_miles(str)
    miles = str[0..-4].to_f
    if str[-2..-1] == "ft"
      miles /= 5280.0
    end
    miles
  end
end

class Route
  attr_accessor :start, :end

  def initialize(start_loc, end_loc)
    @start = start_loc
    @end = end_loc
  end

  #returns true if self has the shortest detour to pick up other_route and false otherwise
  def shortest_detour?(other_route)
    point_a = self.start
    point_b = self.end
    point_c = other_route.start 
    point_d = other_route.end

    detour_1 = Location.driving_distance(point_a, point_c) + Location.driving_distance(point_c, point_d) 
        + Location.driving_distance(point_d, point_b) 

    detour_2 = Location.driving_distance(point_c, point_a) + Location.driving_distance(point_a, point_b) 
        + Location.driving_distance(point_b, point_d)
   
    if detour_1 < detour_2
      return true
    else
     return false
    end 
  end 
end

#example
location_a = Location.new(37.853189, -122.263385)
location_b = Location.new(37.858184, -122.257536)
location_c = Location.new(37.858174, -122.257399)
location_d = Location.new(37.7810487, -122.4115092)


route1 = Route.new(location_a, location_b)
route2 = Route.new(location_c, location_d)

puts route2.shortest_detour?(route1)
