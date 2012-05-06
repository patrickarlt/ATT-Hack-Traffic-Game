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
  field :alerts, type: String

  before_create :update_location_and_alerts

  #has_many :alerts
  #has_many :penalties
  
  def self.preform
   
  end 
  
  def update_location_and_alerts
    anon_user = GEOLOQI.application_post("user/create_anon");
    
    self.geoloqi_access_token = anon_user.access_token

    location = RestClient.get("https://api.att.com/1/devices/tel:#{self.phone_number}/location?access_token=#{self.att_access_token}&requestedAccuracy=1000");

    lat = location["latitude"]
    long = location["longitude"]
    ten_miles = 0.144927536 # in arc degrees
    north = lat + ten_miles
    south = lat - ten_miles
    east = long + ten_miles
    west = long + ten_miles
    boundingBox = "#{north}, #{east}, #{south}, #{west}"
    alerts = Hashie::Mash.new(RestClient.get("http://www.mapquestapi.com/traffic/v1/incidents?key=#{ENV["MAPQUEST_KEY"]}&callback=handleIncidentsResponse&boundingBox=#{boundingBox}&filters=construction,incidents&inFormat=kvp&outFormat=json"))
    self.alerts = alerts
    self.save()
  end
end