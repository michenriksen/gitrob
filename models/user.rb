module Gitrob
  class User
    include DataMapper::Resource

    property :id,         Serial
    property :username,   String, :index => true
    property :name,       String, :index => true, :length => 255
    property :website,    String, :length => 255
    property :location,   String, :length => 512
    property :email,      String, :length => 255
    property :avatar_url, String, :length => 255
    property :url,        String, :length => 255
    property :bio,        String, :length => 1024
    property :created_at, DateTime

    has n, :repos,            :constraint => :destroy
    has n, :blobs,            :constraint => :destroy, :through => :repos
    has n, :findings,         :constraint => :destroy
    belongs_to :organization, :required => false

    def name
      if @name.empty?
        return @username
      end
      super
    end
  end
end
