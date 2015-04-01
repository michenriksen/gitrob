
module Gitrob
  class Blob

    include DataMapper::Resource

    property :id,             Serial
    property :path,           String,  :length => 1024, :index => true
    property :filename,       String,  :length => 255,  :index => true
    property :extension,      String,  :length => 255,  :index => true
    property :size,           Integer, :index => true
    property :findings_count, Integer, :index => true,  :default => 0
    property :created_at,     DateTime

    has n, :findings, :constraint => :destroy
    belongs_to :repo
    belongs_to :organization

    def url
      URI::HTTPS.build({:host => URI(repo.url).host, :path => "/" + URI.escape(owner_name) + "/" + URI.escape(repo.name) + "/blob/master/" + URI.escape(path)}).to_s
    end

    def owner_name
      repo.user.nil? ? repo.organization.login : repo.user.username
    end

    def content
      @content ||= fetch_content
    end

  private

    def fetch_content

      if URI(repo.url).host == "github.com"
        blob_content_url = URI::HTTPS.build({:host => "raw.githubusercontent.com", :path => "/" + URI.escape(owner_name) + "/" + URI.escape(repo.name) + "/master/" + URI.escape(path)}).to_s
      else
        blob_content_url = URI::HTTPS.build({:host => URI(repo.url).host, :path => "/" + URI.escape(owner_name) + "/" + URI.escape(repo.name) + "/raw/master/" + URI.escape(path)}).to_s
      end

      HTTParty.get(blob_content_url).body
      
    end
  end
end
