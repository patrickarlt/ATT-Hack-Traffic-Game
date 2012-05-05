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
  after_create :update_location

  #has_many :alerts
  #has_many :penalties
  
  def self.preform(user_id, task)
   user = self.find(user_id)
   user.update_location if task == "update_location"
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
  end
  
  def create_schedule
    puts ""
    puts ""
    puts "Create Schedule"
    puts self.inspect
    puts ""
    puts ""
    
    Resque.set_schedule('update_user_location', {
      :class => 'User',
      :every => '30s',
      :queue => 'users',
      :args => ["update_location", self.id]})

    #Resque.set_schedule('refresh_token', {
    #  :class => 'User',
    #  :every => '30s',
    #  :queue => 'users',
    #  :args => ["update_location", self.id]})

    #Resque.set_schedule('update_notifications', {
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
  end

  #Update at&t refresh token
  def update_refresh_token
  end

  #Update alerts
  def update_alerts
  end
end