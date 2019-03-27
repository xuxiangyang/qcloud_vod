module QcloudVod
  class Client
    attr_accessor :region, :access_id, :access_key, :http, :http_v2

    def initialize(region: nil, access_id: nil, access_key: nil)
      @region = region
      @access_id = access_id
      @access_key = access_key
      @http = QcloudVod::Http.new(region: region, access_id: access_id, access_key: access_key)
      @http_v2 = QcloudVod::HttpV2.new(region: region, access_id: access_id, access_key: access_key)
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

    def pull_vod_file(file_name, url, class_id = nil, params = {})
      params["pullset.0.url"] = url
      params["pullset.0.fileName"] = file_name
      params["pullset.0.classId"] = class_id if class_id
      http_v2.get("MultiPullVodFile", params)
    end

    def get_video_info(file_id, params = {})
      params["fileId"] = file_id
      http_v2.get("GetVideoInfo", params)
    end

    def sample_snapshots(file_id, template_id)
      http_v2.get("ProcessFile", "fileId" => file_id, "sampleSnapshot.definition" => template_id)
    end
  end
end
