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
      "https://github.com/#{URI.escape(owner_name)}/#{URI.escape(repo.name)}/blob/master/#{URI.escape(path)}"
    end

    def owner_name
      repo.user.nil? ? repo.organization.login : repo.user.username
    end

    def content
      @content ||= fetch_content
    end

  private

    def fetch_content
      HTTParty.get("https://raw.githubusercontent.com/#{URI.escape(owner_name)}/#{URI.escape(repo.name)}/master/#{URI.escape(path)}").body
    end
  end
end
