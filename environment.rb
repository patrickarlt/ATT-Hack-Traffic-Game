ENV['RACK_ENV'] ||= 'development'
Encoding.default_internal = 'UTF-8'
require 'rubygems'
require 'bundler/setup'
Bundler.require

puts "Starting in #{ENV['RACK_ENV']} mode.."


def client
  OAuth2::Client.new((ENV['ATT_API_KEY']||'testing'),
                     (ENV['ATT_SECRET']||'testing'),
                     :site => 'http://api.att.com',
                     :authorize_url => 'http://api.att.com/oauth/authorize',
                     :token_url => 'http://api.att.com/oauth/access_token')
end

def redirect_uri(path = '/auth/callback', query = nil)
  uri = URI.parse(request.url)
  uri.path  = path
  uri.query = query
  uri.to_s
end


Dir.glob(%w{lib/** helpers models}.map! {|d| File.join d, '*.rb'}).each {|f| require_relative f}

class Controller < Sinatra::Base

  # Load Configuration Variables  
  @_config = Hashie::Mash.new YAML.load_file('./config/config.yaml')[ENV['RACK_ENV'].to_s]
  def self.Settings
    @_config
  end
  
  helpers  Sinatra::UserAgentHelpers
  
  # Set Sinatra Root
  set :root,            File.dirname(__FILE__)
  set :views,           'views'
  set :public_folder,   'public'
  set :erubis,          :escape_html => true
  set :sessions,        true
  set :session_secret,  @_config.session_secret

  # Development Specific Configuration
  configure :development do
    Bundler.require :development
    use Rack::ShowExceptions
  end

  # Test Specific Configuration
  configure :test do
    Bundler.require :test
  end

  # Production Specific Configuration
  configure :production do
    Bundler.require :production
  end

  # Set controller names so we can map them in the config.ru file.
  set :controller_names, []
  Dir.glob('controllers/*.rb').each do |file|
    settings.controller_names << File.basename(file, '.rb')
  end

  # Params Shortcut
  def p; params end

  # Initialize MongoID
  #Mongoid.load!(File.join(settings.root,"config","mongoid.yaml"))
  #Mongoid.logger = Logger.new($stdout, :info) if ENV['RACK_ENV'] == "development"
  
  #GEOLOQI = Geoloqi::Session.new :access_token => @_config.geoloqi_application_access_token, :config => {:client_id => @_config.geoloqi_client_id, :client_secret => @_config.geoloqi_client_secret}

  # Initialize Redis and Resque
  configure do
    redis_config = URI.parse(ENV['REDISTOGO_URL'])
    puts redis_config
    REDIS = Redis.new("host" => redis_config.host, "port" => redis_config.port, "password" => redis_config.password)
    Resque.redis = REDIS
  end

end

# Require Controllers
require_relative './controller.rb'
Dir.glob(['controllers'].map! {|d| File.join d, '*.rb'}).each do |f| 
  require_relative f
  
  # Ugly fix to include the asset code until the inheritance bug is fixed.
  (Controller.controller_names << 'controller').each do |controller|
    eval "#{controller.capitalize}.send(:include, Assets)"
  end
end