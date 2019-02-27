module QcloudVod
  class Client
    attr_accessor :region, :access_id, :access_key, :http

    def initialize(region: nil, access_id: nil, access_key: nil)
      @region = region
      @access_id = access_id
      @access_key = access_key
      @http = QcloudVod::Http.new(region: region, access_id: access_id, access_key: access_key)
    end

    def describe_class
      res = http.get("DescribeAllClass", "2018-07-17")
      res["Response"]["ClassInfoSet"]
    end

    def apply_upload(media_type, params = {})
      params["MediaType"] = media_type
      res = http.get("ApplyUpload", "2018-07-17", params)
      res["Response"]
    end

    def commit_upload(vod_session_key, params = {})
      params["VodSessionKey"] = vod_session_key
      res = http.get("CommitUpload", "2018-07-17", params)
      res["Response"]
    end
  end
end
