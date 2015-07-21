module Gitrob
  class Repo
    include DataMapper::Resource

    property :id, Serial
    property :name, String,        :index => true, :length => 255
    property :owner_name, String,  :index => true
    property :description, String, :length => 1024
    property :website, String,     :length => 255
    property :url, String,         :length => 255
    property :created_at, DateTime

    has n, :blobs,            :constraint => :destroy
    has n, :findings,         :constraint => :destroy
    belongs_to :user,         :required => false
    belongs_to :organization

    def full_name
      [owner_name, name].join('/')
    end

    def last_update
      created_at
    end
  end
end
