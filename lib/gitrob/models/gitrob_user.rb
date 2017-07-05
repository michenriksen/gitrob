#Zendesk - Gitrob User Model
module Gitrob
  module Models
    class GitrobUser < Sequel::Model
      plugin :secure_password, include_validations: false
      set_allowed_columns :username, :password_digest

      def validate
        super
        validates_presence [:username, :password_digest]
      end
    end
  end
end
