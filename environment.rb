ENV['RACK_ENV'] ||= 'development'
Encoding.default_internal = 'UTF-8'
require 'rubygems'
require 'bundler/setup'
Bundler.require

puts "Starting in #{ENV['RACK_ENV']} mode.."

Dir.glob(%w{lib/** helpers models}.map! {|d| File.join d, '*.rb'}).each {|f| require_relative f}

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
  Mongoid.load!(File.join(settings.root,"config","mongoid.yaml"))
  Mongoid.logger = Logger.new($stdout, :info) if ENV['RACK_ENV'] == "development"
  
  GEOLOQI = Geoloqi::Session.new :access_token => @_config.geoloqi_application_access_token, :config => {:client_id => @_config.geoloqi_client_id, :client_secret => @_config.geoloqi_client_secret, :use_hashie_mash => true}

  # Initialize Redis and Resque
  configure do
    redis_config = URI.parse(ENV['REDISTOGO_URL'])
    REDIS = Redis.new("host" => redis_config.host, "port" => redis_config.port, "password" => redis_config.password)
    Resque.redis = REDIS
  end

# Require Controllers
require_relative './controller.rb'