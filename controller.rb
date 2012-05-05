helpers do
  def client
    OAuth2::Client.new((ENV['ATT_API_KEY']||'testing'),
                       (ENV['ATT_SECRET']||'testing'),
                       :site => 'https://api.att.com',
                       :authorize_url => 'https://api.att.com/oauth/authorize',
                       :token_url => 'https://api.att.com/oauth/token')
  end

  def redirect_uri(path = '/auth/callback', query = nil)
    uri = URI.parse(request.url)
    uri.path  = path
    uri.query = query
    uri.to_s
  end
end

  get "/" do
    erb :index
  end
  
  get "/destory_all" do
    User.delete_all
  end
  
  get '/auth' do
    session[:phone] = params[:phone].delete "-"
    authorization_url = client.auth_code.authorize_url(:redirect_uri => redirect_uri, :response_type => "client_credentials", :scope => "TL")
    puts "Redirecting to URL: #{authorization_url.inspect}"
    redirect authorization_url
  end

  get '/auth/callback' do
    puts "Callback"
    auth_token = params[:code]
    access_token = RestClient.post("https://api.att.com/oauth/token", {
      grant_type: "authorization_code", 
      client_id: ENV['ATT_API_KEY'],
      client_secret: ENV['ATT_SECRET'],
      code: auth_token
    })
    User.create({
      att_access_token: access_token[:access_token],
      att_refresh_token: access_token[:refresh_token],
      att_token_expires: access_token[:expires_in],
      phone_number: session[:phone]
    })
  end

  get '/auth/failure' do
    erb "<h1>Authentication Failed:</h1><h3>message:<h3> <pre>#{params}</pre>"
  end
