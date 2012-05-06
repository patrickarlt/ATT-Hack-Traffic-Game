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
    data = JSON.parse(request.body.read)
    @account_sid = 'ACb1215d32cb9641c4b6e37526dd29f981'
    @auth_token = "e9c98d111c0471cc236d0c7a942276ad"

    # set up a client to talk to the Twilio REST API
    @client = Twilio::REST::Client.new(@account_sid, @auth_token)


    @account = @client.account
    @message = @account.sms.messages.create({:from => '+14155992671', :to => '5034222345', :body => data["place"]["extra"]["description"]);
    puts @message
  end

  get '/callback/alert' do
    RestClient.post('https://api.twilio.com/2010-04-01/Accounts/ACb1215d32cb9641c4b6e37526dd29f981/SMS/Messages.json', {
       from:
       to:
       body:
    });
      
      -d 'From=%2B14155992671' -d 'To=5034222345' -d 'Body=There'\''s+an+aciident+near+you%21' -u ACb1215d32cb9641c4b6e37526dd29f981:e9c98d111c0471cc236d0c7a942276ad)

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

      "#{access_token.inspect}+ <br><br><br> #{location.inspect} <br><br><br> #{User.inspect}"
    rescue OAuth2::Error => e
      erb %(<p>#{$!}</p><p><a href="/auth">Retry</a></p>)
    end
  end
    
  get '/auth/failure' do
    erb "<h1>Authentication Failed:</h1><h3>message:<h3> <pre>#{params}</pre>"
  end
