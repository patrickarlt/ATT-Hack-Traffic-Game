helpers do
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
end