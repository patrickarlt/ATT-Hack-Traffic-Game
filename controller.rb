helpers do
  def client
    OAuth2::Client.new(ENV['ATT_API_KEY'], ENV['ATT_SECRET'],{
                       :site => 'https://api.att.com',
                       :authorize_url => 'https://api.att.com/oauth/authorize',
                       :token_url => 'https://api.att.com/oauth/token'})

  end

  def redirect_uri(path = '/auth/callback', query = nil)
    uri = URI.parse(request.url)
    uri.path  = path
    uri.query = query
    uri.to_s
  end
end

  get "/" do
    REDIS.set("woot", "cool");
    REDIS.get("woot");
    erb :index
  end

  get "/user" do
    user = User.first().entries;
    puts ""
    puts user.inspect
    puts ""
    "#{user.inspect}"
  end
  
  get '/auth' do
    session[:phone] = params[:phone].delete "-"
    authorization_url = client.auth_code.authorize_url(:redirect_uri => redirect_uri, :response_type => "client_credentials", :scope => "TL")
    puts "Redirecting to URL: #{authorization_url.inspect}"
    redirect authorization_url
  end

  get '/auth/callback' do
    begin
      access_token = client.auth_code.get_token(params[:code], :redirect_uri => redirect_uri)
      
      puts "access_token.inspect"
      puts access_token.inspect
      
      User.create({
        att_access_token: access_token.token,
        att_refresh_token: access_token.refresh_token,
        att_token_expires: access_token.expires_at,
        phone_number: session[:phone]
      })
      
      "#{access_token.inspect}"
    rescue OAuth2::Error => e
      erb %(<p>#{$!}</p><p><a href="/auth">Retry</a></p>)
    end
  end
    
  get '/auth/failure' do
    erb "<h1>Authentication Failed:</h1><h3>message:<h3> <pre>#{params}</pre>"
  end
