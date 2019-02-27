require 'digest'
require 'openssl'
require 'net/http'
require 'cgi'
require "base64"
module QcloudVod
  class Http
    attr_accessor :region, :access_id, :access_key

    def initialize(region: nil, access_id: nil, access_key: nil)
      @region = region
      @access_id = access_id
      @access_key = access_key
    end

    def get(action, version, params = {})
      params["Action"] = action
      params["Region"] ||= region
      params["Timestamp"] = Time.now.to_i
      params["Nonce"] = rand(10**10)
      params["Version"] = version
      params["SecretId"] = access_id
      params["SignatureMethod"] = "HmacSHA1"

      query_string = params.sort_by { |k, _| k }.map { |k, v| "#{k}=#{v}" }.join("&")
      sign_string = "GET#{host}/?#{query_string}"
      params["Signature"] = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA1", access_key, sign_string))
      query_string = params.sort_by { |k, _| k }.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join("&")
      res = Net::HTTP.get URI.parse("https://#{host}/?#{query_string}")
      result = ActiveSupport::HashWithIndifferentAccess.new(JSON.parse(res))
      raise QcloudVod::Http::ResponseError.new(action, res) if result['Response']['Error']
      result
    end

    def request_v3(request_klass, path, body = nil, headers = {})
      uri = URI.join("https://#{host}", path)

      params = Hash[uri.query.split("&").map { |s| s.split('=') }]

      headers["Host"] ||= host
      headers["Content-Type "] ||= "application/json"
      headers["X-TC-Region"] ||= params["Region"] || region
      headers["X-TC-Timestamp"] ||= Time.now.to_i.to_s
      headers["X-TC-Version"] ||= params["Version"]
      headers["X-TC-Action"] ||= params["Action"]
      headers["Authorization"] = "TC3-HMAC-SHA256 Credential=#{access_id}/#{Time.now.utc.strftime('%Y-%m-%d')}/vod/tc3_request,SignedHeaders=#{headers.keys.sort.map(&:downcase).join(';')},Signature=#{compute_auth(request_klass::METHOD, path, body, headers)}"

      request = request_klass.new(URI.parse("https://#{host}"), headers)
      request.body = body
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", verify_mode: OpenSSL::SSL::VERIFY_NONE) { |http| http.request(request) }
    end

    def host
      region ? "vod.#{region}.tencentcloudapi.com" : "vod.tencentcloudapi.com"
    end

    def compute_auth(method, path, body = nil, headers = {})
      _, query_string = path.split("?")
      canonical_request = "#{method.upcase}\n/\n#{query_string}\n#{headers.sort_by { |k, _| k }.map { |k, v| "#{k}:#{v}" }.join("\n")}\n#{headers.keys.map(&:downcase).join(';')}\n#{Digest::SHA256.hexdigest(body || '').downcase}"
      credential_date = Time.now.utc.strftime('%Y-%m-%d')
      string_to_sign = "TC3-HMAC-SHA256\n#{headers['X-TC-Timestamp']}\n#{credential_date}/vod/tc3_request\n#{Digest::SHA256.hexdigest(canonical_request).downcase}"
      secret_date = OpenSSL::HMAC.hexdigest("SHA256", "TC3#{access_key}", credential_date)
      secret_service = OpenSSL::HMAC.hexdigest("SHA256", secret_date, 'vod')
      secret_signing = OpenSSL::HMAC.hexdigest("SHA256", secret_service, "tc3_request")
      OpenSSL::HMAC.hexdigest("SHA256", secret_signing, string_to_sign)
    end

    class ResponseError < QcloudVod::Error
      def initialize(action, res)
        super("Wrong response code with #{res} while #{action}")
      end
    end
  end
end
