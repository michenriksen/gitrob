module Gitrob
  module Models
    class GithubAccessToken < Sequel::Model
      set_allowed_columns :token

      TOKEN_REGEX = /[a-f0-9]{40}/

      many_to_one :assessment

      def validate
        super
        validates_presence [:token]
        validates_format TOKEN_REGEX, :token
      end
    end
  end
end
