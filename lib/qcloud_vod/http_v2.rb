module QcloudVod
  class HttpV2
    attr_accessor :region, :access_id, :access_key
    def initialize(region: nil, access_id: nil, access_key: nil)
      @region = region
      @access_id = access_id
      @access_key = access_key
    end

    def get(action, params = {})
      params["Action"] = action
      params["Region"] = region
      params["Timestamp"] = Time.now.to_i
      params["Nonce"] = rand(10**10)
      params["SecretId"] = access_id
      params["SignatureMethod"] = "HmacSHA1"
      query_string = params.sort_by { |k, _| k }.map { |k, v| "#{k}=#{v}" }.join("&")
      sign_string = "GETvod.api.qcloud.com/v2/index.php?#{query_string}"
      params["Signature"] = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA1", access_key, sign_string))
      query_string = params.sort_by { |k, _| k }.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join("&")
      res = Net::HTTP.get URI.parse("https://vod.api.qcloud.com/v2/index.php?#{query_string}")
      ActiveSupport::HashWithIndifferentAccess.new(JSON.parse(res))
    end
  end
end
