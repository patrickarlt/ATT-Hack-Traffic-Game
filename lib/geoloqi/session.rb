module Geoloqi
  class Session
    def application_get(path, opts={})
      get path, opts, {"Authorization" => "Basic " + Base64.strict_encode64(@config.client_id + ":" + @config.client_secret)}
    end

    def application_post(path, opts={})
      post path, opts, {"Authorization" => "Basic " + Base64.strict_encode64(@config.client_id + ":" + @config.client_secret)}
    end
  end
end