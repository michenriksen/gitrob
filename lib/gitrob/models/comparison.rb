module Gitrob
  module Models
    class Comparison < Sequel::Model
      set_allowed_columns :primary_assessment, :secondary_assessment

      many_to_one :primary_assessment,
                  :class => :"Gitrob::Models::Assessment"
      many_to_one :secondary_assessment,
                  :class => :"Gitrob::Models::Assessment"
      many_to_many :blobs
      many_to_many :repositories
      many_to_many :owners
    end
  end
end
