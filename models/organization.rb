module Gitrob
  class Organization
    include DataMapper::Resource

    property :id,         Serial
    property :name,       String, :length => 255, :index => true
    property :login,      String, :length => 255, :index => true
    property :website,    String, :length => 255
    property :location,   String, :length => 255
    property :email,      String, :length => 255
    property :avatar_url, String, :length => 255
    property :url,        String, :length => 255
    property :created_at, DateTime

    has n, :repos,        :constraint => :destroy
    has n, :users,        :constraint => :destroy
    has n, :blobs,        :constraint => :destroy
    has n, :findings,     :constraint => :destroy

    def username
      @login
    end

    def bio
      nil
    end

    def name
      @name.to_s.empty? ? @login : @name
    end
  end
end
