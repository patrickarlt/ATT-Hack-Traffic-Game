class User

  @queue = :users

  include Mongoid::Document
  
  #ATT specific
  field :phone_number, type: String
  field :att_access_token, type: String
  field :att_refresh_token, type: String
  field :att_token_expires, type: Integer

  #When Location Was Last Updated
  field :last_location, type: Hash
  field :last_location_update, type: Date
  
  #When Places were last synced
  field :last_place_sync, type: Date
  
  #geoloqi specific
  field :geoloqi_access_token, type: String
  
  before_create :create_geoloqi_user
  after_create :create_schedule

  #has_many :alerts
  #has_many :penalties
  
  def self.preform
   
  end 
  
  def create_geoloqi_user
    anon_user = GEOLOQI.application_post("user/create_anon");
    puts ""
    puts ""
    puts "Create Geoloqi User"
    puts anon_user.inspect
    puts ""
    puts ""
    
    self.geoloqi_access_token = anon_user.access_token
    self.update_location
  end
  
  def create_schedule
    puts ""
    puts ""
    puts "Create Schedule"
    puts self.inspect
    puts ""
    puts ""
    
    #Resque::Scheduler.set_schedule('update_user_location', {
    #  :class => 'User',
    #  :every => '30s',
    #  :queue => 'users',
    #  :args => ["update_location", self.id]})

    #Resque::Scheduler.set_schedule('refresh_token', {
    #  :class => 'User',
    #  :every => '30s',
    #  :queue => 'users',
    #  :args => ["update_location", self.id]})

    #Resque::Scheduler.set_schedule('update_alert', {
    #  :class => 'User',
    #  :every => '30s',
    #  :queue => 'users',
    #  :args => ["update_location", self.id]})

  end

  #Update a users location (using at&t)
  def update_location
    puts ""
    puts ""
    puts "Update Location"
    puts self.inspect
    puts ""
    puts self.phone_number
    puts self.att_access_token
    location = RestClient.get("https://api.att.com/1/devices/tel:#{self.phone_number}/location?access_token=#{self.att_access_token}&requestedAccuracy=1000");
    puts location.inspect
    puts ""
    puts ""
    self.last_location = {
      latitude: location["latitude"],
      longitude: location["longitude"]
    }  
  end
  
  #Update at&t refresh token
  def update_refresh_token
  end

  #Update alerts
  def update_alerts
    lat = self.last_location.latitude.to_i
    long = self.last_location.longitude.to_i
    ten_miles = 0.144927536 # in arc degrees
    north = lat + ten_miles
    south = lat - ten_miles
    east = long + ten_miles
    west = long + ten_miles
    boundingBox = "#{north}, #{east}, #{south}, #{west}"
    alerts = Hashie::Mash.new(RestClient.get("http://www.mapquestapi.com/traffic/v1/incidents?key=#{ENV["MAPQUEST_KEY"]}&callback=handleIncidentsResponse&boundingBox=#{boundingBox}&filters=construction,incidents&inFormat=kvp&outFormat=json"))
  end
end