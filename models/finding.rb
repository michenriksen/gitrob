module Gitrob
  class Finding
    include DataMapper::Resource

    property :id,          Serial
    property :caption,     String, :length => 255
    property :description, Text

    belongs_to :blob
    belongs_to :repo
    belongs_to :user,         :required => false
    belongs_to :organization
  end
end
