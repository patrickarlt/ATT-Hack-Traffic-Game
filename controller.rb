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
    erb :index
  end

  get "/user" do
    test = ""
    User.all_in.each do |user|
      user.update_location_and_alerts()
      test += user.to_json
    end
    halt 200, test
  end
  
  get '/callback/leaving' do
    "ok"
  end

  get '/callback/alert' do
    data = {
      "place"=> {
        "place_id"=> "200",
         "name"=> "Palo Alto",
         "latitude"=> "37.441898",
         "longitude"=> "-122.141899",
         "extra"=> {
            "description"=>"Car accident ahead!",
            "mq_id" => "200",
            "traffic_jam_url"=> "hollow-fog-8448.herokuapp.com/og/traffic_jam_200.html"
         }
      }
    }
    latitude = data["place"]["latitude"]
    longitude = data["place"]["longitude"]
    description = data["place"]["extra"]["description"]
    mq_id = data["place"]["extra"]["mq_id"]
    
    #latitude
    #description
    #longitude
    #mqid

    #data = JSON.parse(request.body.read)

    #create_traffic_jam_object(mq_id, description, latitude, longitude)

    @account_sid = 'ACb1215d32cb9641c4b6e37526dd29f981'
    @auth_token = "e9c98d111c0471cc236d0c7a942276ad"

    # set up a client to talk to the Twilio REST API
    @client = Twilio::REST::Client.new(@account_sid, @auth_token)

    @account = @client.account
    @message = @account.sms.messages.create({:from => '+14155992671', :to => '7348833328', :body => description})
    halt 200, "ok"
  end
  
  get '/callback/penalty' do
  
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

      user = User.create({
        att_access_token: access_token.token,
        att_refresh_token: access_token.refresh_token,
        att_token_expires: access_token.expires_at,
        phone_number: session[:phone]
      })

      location = RestClient.get("https://api.att.com/1/devices/tel:#{user.phone_number}/location?access_token=#{user.att_access_token}&requestedAccuracy=1000");

      "<h1>You Are Signed Up!</h1>"
    rescue OAuth2::Error => e
      erb %(<p>#{$!}</p><p><a href="/auth">Retry</a></p>)
    end
  end
    
  get '/auth/failure' do
    erb "<h1>Authentication Failed:</h1><h3>message:<h3> <pre>#{params}</pre>"
  end

  helpers do
  def host
    request.env['HTTP_HOST']
  end

  def scheme
    request.scheme
  end

  def url_no_scheme(path = '')
    "//#{host}#{path}"
  end

  def url(path = '')
    "#{scheme}://#{host}#{path}"
  end

  def authenticator
    @authenticator ||= Koala::Facebook::OAuth.new(ENV["FACEBOOK_APP_ID"], ENV["FACEBOOK_SECRET"], url("/auth/facebook/callback"))
  end

  # List of helper functions to connect with facebook open graph:
  # create open graph webpage and publish action to facebook given location, start and end time
  def create_traffic_jam_object(mq_id, mq_msg, lat, lng)
    mq_reverse_geocode_url = "http://www.mapquestapi.com/geocoding/v1/reverse?key="+ENV["MAPQUEST_KEY"]+"&lat=#{lat}&lng=#{lng}"
    response = RestClient.get mq_reverse_geocode_url
    response = JSON.parse(response)
    response = response['results'][0]['locations'][0]
    location = response['street'];
    # Add city
    if location.nil?
      location = response['adminArea5']
    elsif !response['adminArea5'].nil?
      location = location + ', ' + response['adminArea5']
    end
    # Add state
    if location.nil?
      location = response['adminArea3']
    elsif !response['adminArea3'].nil?
      location = location + ', ' + response['adminArea3']
    end
    # Add country
    if location.nil?
      location = response['adminArea1']
    elsif !response['adminArea1'].nil?
      location = location + ', ' + response['adminArea1']
    end
    
    relative_path = "/og/traffic_jam_#{mq_id}.html"
    absolute_path = "#{File.dirname(__FILE__)}/public#{relative_path}"
    public_path = "#{url('')}#{relative_path}"

    template =
      "<head prefix=\"og: http://ogp.me/ns# fb: http://ogp.me/ns/fb# #{ENV['FACEBOOK_NAMESPACE']}: http://ogp.me/ns/fb/#{ENV['FACEBOOK_NAMESPACE']}#\">\n" +
        "<meta property=\"fb:app_id\"                      content=\"#{ENV['FACEBOOK_APP_ID']}\" />\n" +
        "<meta property=\"og:type\"                        content=\"#{ENV['FACEBOOK_NAMESPACE']}:traffic_jam\" />\n" +
        "<meta property=\"og:url\"                         content=\"#{public_path}\" />\n" +
        "<meta property=\"og:title\"                       content=\"#{location}\" />\n" +
        "<meta property=\"og:image\"                       content=\"#{url('')}/images/traffic-jam-delay.jpg\" />\n" +
        "<meta property=\"#{ENV['FACEBOOK_NAMESPACE']}:location:latitude\"  content=\"#{lat}\" />\n" +
        "<meta property=\"#{ENV['FACEBOOK_NAMESPACE']}:location:longitude\" content=\"#{lng}\" />\n" +
      "</head>\n" +
      "<body>\n" +
        "<h1>#{location}</h1>\n" +
      "</body>\n"
    page = File.new(absolute_path, "w")
    page.write(template)
    page.close()
    public_path 
  end

  def publish_traffic_jam_avoid_action(gl_user_id, gl_traffic_jam_url, gl_loc_name, gl_loc_lat, gl_loc_lng)
    # TODO: get access token and fb_user_id from gl_user_id

    # sample access token for test user
    #access_token = 'AAAFErKQRIfYBABRVhZCRrF6cLT3qDH8EVZADY4ElGFnU9q56OoggcoviO0pPkmRHgF50AVTkVfzgExrxwoPdz0p0CZCHvZAZCgkCeUhbw2gZDZD'
    #access_token = "AAAFRO8jyhBYBAHFUHMKkbQFOv9aMj7LILNGb3fJc3PzrYOfW3GhetFsRWLJhOUPCsObdafUqxTZBJ9PYAisOIJsIjcU1h1rmaaGZBGVQZDZD"
    access_token = "AAAFRO8jyhBYBAJ6GJhr4KNkjkjWD3obflPZCvZAM2rYVJZCTYdRQen3jEOaZCDF5bZCWWsqtepNZBWtgBEgc5a8F4qN47YMw8q17N7baqaygZDZD"
    avoid_image_url = "#{url('')}/images/traffic-jam-avoid.jpg"
    # Get base API Connection
    @graph  = Koala::Facebook::API.new(access_token)
    # publish action
    @graph.graph_call("me/#{ENV['FACEBOOK_NAMESPACE']}:avoid", {:traffic_jam => gl_traffic_jam_url, :image => avoid_image_url}, "post") do |result|
      result
    end
  end

end

# the facebook session expired! reset ours and restart the process
error(Koala::Facebook::APIError) do
  @gl_traffic_jam_url + "<br>" + "error: #{request.env['sinatra.error'].to_s}"
  #session[:access_token] = nil
  #redirect "/auth/facebook"
end

# used by Canvas apps - redirect the POST to be a regular GET
post "/" do
  redirect "/"
end

# used to close the browser window opened to post to wall/send to friends
get "/close" do
  "<body onload='window.close();'/>"
end

get "/sign_out" do
  session[:access_token] = nil
  redirect '/'
end

get "/auth/facebook" do
  session[:access_token] = nil
  redirect authenticator.url_for_oauth_code(:permissions => FACEBOOK_SCOPE)
end

get '/auth/facebook/callback' do
  session[:access_token] = authenticator.get_access_token(params[:code])
  redirect '/'
end

get '/publish' do
    @gl_traffic_jam_url = url('') + "/og/traffic_jam_#{params[:num]}.html"
    puts @gl_traffic_jam_url
    publish_traffic_jam_avoid_action('', @gl_traffic_jam_url,'Mountain View', 37.3861, -122.083)
end

get '/create' do
    location = create_traffic_jam_object(params[:num], "Car accident ahead!!", 40.0755, -76.329999)
    location
end