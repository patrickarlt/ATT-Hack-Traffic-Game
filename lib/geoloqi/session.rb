module Geoloqi
  class Session
    def application_get(path, opts={})
      get path, opts, {"Authorization" => "Basic " + Base64.strict_encode64(ENV["GEOLOQI_CLIENT_ID"] + ":" + ENV["GEOLOQI_CLIENT_SECRET"])}
    end

    def application_post(path, opts={})
      post path, opts, {"Authorization" => "Basic " + Base64.strict_encode64(ENV["GEOLOQI_CLIENT_ID"] + ":" + ENV["GEOLOQI_CLIENT_SECRET"])}
    end
  end
end