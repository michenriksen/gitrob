module Gitrob
  module Models
    class Owner < Sequel::Model
      set_allowed_columns :github_id, :login, :type, :url,
                          :html_url, :avatar_url, :name, :blog,
                          :location, :email, :bio

      ALLOWED_TYPES = %w(User Organization)

      one_to_many :repositories
      one_to_many :blobs
      many_to_one :assessment
      many_to_many :comparisons

      def validate
        super
        validates_presence [:github_id, :login, :type, :url,
                            :html_url, :avatar_url]
        validates_includes ALLOWED_TYPES, :type
      end
    end
  end
end
