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

    JSON.parse(location)
    
    #lat = location["latitude"].to_i
    #long = location["longitude"].to_i
    lat = 37.443012503777
    long = -122.1582415379
    ten_miles = 0.144927536 # in arc degrees
    north = (lat + ten_miles)
    south = (lat - ten_miles)
    east = (long + ten_miles)
    west = (long + ten_miles)
    boundingBox = "#{north},#{east},#{south},#{west}"
    #alerts_raw = RestClient.get("http://www.mapquestapi.com/traffic/v1/incidents?key=#{ENV["MAPQUEST_KEY"]}&boundingBox=#{boundingBox}&filters=construction,incidents&inFormat=kvp&outFormat=json")
    alerts_raw = RestClient.get("http://www.mapquestapi.com/traffic/v1/incidents?key=ENV[%22MAPQUEST_KEY%22]&boundingBox=37.660066,-122.415976,37.223928,-121.866659&filters=construction,incidents&inFormat=kvp&outFormat=json")
    alerts = JSON.parse(alerts_raw)
    alerts["incidents"].each do |alert|
      
      alert_place = Geoloqi.post(self.geoloqi_access_token, "trigger/create", {
        latitude: alert["lat"],
        longitude: alert["long"],
        type: "callback",
        url: "http://hollow-fog-8448.herokuapp.com/callback/alert",
        trigger_on: "enter",
        date_from: alert["startTime"],
        date_to: alert["endTime"],
        radius:1000,
        extra: {
          description: alert["fullDesc"],
          mq_id: alert["id"],
          traffic_jam_url: "http://hollow-fog-8448.herokuapp.com/og/traffic_jam_#{alert['id']}"
        }
      })
      
      leaving_place = Geoloqi.post(self.geoloqi_access_token, "trigger/create", {
        place_id: alert_place["place_id"],
        trigger_on: "enter",
        type: "callback",
        url: "http://hollow-fog-8448.herokuapp.com/callback/leaving"
      })

      penalty_place = Geoloqi.post(self.geoloqi_access_token, "place/create", {
        latitude: alert["lat"],
        longitude: alert["long"],
        trigger_on: "enter",
        date_from: alert["startTime"],
        date_to: alert["endTime"],
        type: "callback",
        url: "http://hollow-fog-8448.herokuapp.com/callback/penalty",
        radius:100,
        extra: {
          description: alert["fullDesc"],
          mq_id: alert["id"],
          traffic_jam_url: "http://hollow-fog-8448.herokuapp.com/og/traffic_jam_#{alert['id']}"
        }
      })

    end
  end
end