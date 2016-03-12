module Gitrob
  module Models
    class Repository < Sequel::Model
      set_allowed_columns :github_id, :name, :full_name, :description,
                          :private, :url, :html_url, :homepage, :size,
                          :default_branch

      one_to_many :blobs
      many_to_one :assessment
      many_to_one :owner
      many_to_many :comparisons

      def validate
        super
        validates_presence [:github_id, :name, :full_name, :private,
                            :url, :html_url, :size, :default_branch]
      end
    end
  end
end
