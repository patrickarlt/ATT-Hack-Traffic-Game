class Controller < Sinatra::Base



def client
  OAuth2::Client.new((ENV['ATT_API_KEY']||'testing'),
                     (ENV['ATT_SECRET']||'testing'),
                     :site => 'http://api.att.com',
                     :authorize_url => 'http://api.att.com/oauth/authorize',
                     :token_url => 'http://api.att.com/oauth/access_token')
end
# redirect = http://hollow-fog-8448.herokuapp.com/auth/callback
get "/" do
  erb :index
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
    api_url = "/1/devices/tel:#{session[:phone]}/location?access_token=#{access_token.token}&requestedAccuracy=1000"
    location = JSON.parse(access_token.get(api_url).body)
    erb "<p>Your location:\n#{location.inspect}</p>"
  rescue OAuth2::Error => e
    erb %(<p>#{$!}</p><p><a href="/auth">Retry</a></p>)
  end
end

get '/auth/failure' do
  erb "<h1>Authentication Failed:</h1><h3>message:<h3> <pre>#{params}</pre>"
end

def redirect_uri(path = '/auth/callback', query = nil)
  uri = URI.parse(request.url)
  uri.path  = path
  uri.query = query
  uri.to_s
end


  


end