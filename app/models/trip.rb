class Trip < ActiveRecord::Base
  require './app/lib/modules/google_maps/google_maps.rb'
  require './app/lib/modules/uber/uber.rb'
  require './app/lib/algorithms/dollars.rb'
  require './app/lib/algorithms/distance.rb'
  require './app/lib/algorithms/duration.rb'
  require './app/lib/algorithms/weather_algorithm.rb'


  belongs_to :user
  has_one :origin, class_name: 'Location'
  has_one :destination, class_name: 'Location'
  has_many :routes

  def set_origin(origin_str, user)
    self.origin = Location.new(address: origin_str, user: user)
  end

  def set_destination(destination_str, user)
    self.destination = Location.new(address: destination_str, user: user)
  end

  def google_routes
    GoogleMaps.run(self)
  end

  def generate_and_score_routes
    routes = []
    self.google_routes.each do |gr|
      puts gr.travel_mode
      if gr.travel_mode == 'driving'
        # binding.pry
        #setup and shovel in driving route and uber route and cab route
        r = Route.new(travel_mode: gr.travel_mode)
        r.calculate_and_set_all_exp(gr)
        routes << r

        uber_r = Route.new(travel_mode: 'uber')
        uber = UberParser.run(gr)
        uber_r.calculate_and_set_all_exp(uber)
        routes << uber_r

        cab_r = Route.new(travel_mode: 'cab')
        gr.travel_mode = cab_r.travel_mode
        cab_r.calculate_and_set_all_exp(gr)
        routes << cab_r

      elsif gr.travel_mode == 'bicycling'
        #setup and shovel in bicycling and divvy route
        r = Route.new(travel_mode: gr.travel_mode)
        r.calculate_and_set_all_exp(gr)
        routes << r

        divvy_r = Route.new(travel_mode: 'divvy')
        gr.travel_mode = 'divvy'
        divvy_r.calculate_and_set_all_exp(gr)
        routes << divvy_r

      else # subway, bus, walking
        r = Route.new(travel_mode: gr.travel_mode)
        r.calculate_and_set_all_exp(gr)
        routes << r
      end
    end
    # something for cab
    # something for divvy
    routes.sort_by!{ |r| r.total_exp }
    routes.reverse!
  end
end
