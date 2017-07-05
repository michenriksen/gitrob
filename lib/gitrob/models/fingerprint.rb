#Zendesk - FalsePositive Model
module Gitrob
  module Models
    class FalsePositive < Sequel::Model
      set_allowed_columns :fingerprint, :path, :repository
      
      SHA_REGEX = /[a-f0-9]{64}/
      
      def validate
        super
        validates_unique(:fingerprint, :path, :repository)
        validates_presence [:fingerprint, :path, :repository]
        validates_format SHA_REGEX, :fingerprint
      end
    end
  end
end
