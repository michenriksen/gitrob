module Gitrob
  module Models
    class Flag < Sequel::Model
      set_allowed_columns :caption, :description, :assessment

      many_to_one :blob
      many_to_one :assessment

      def validate
        super
        validates_presence [:caption]
      end
    end
  end
end
