module Gitrob
  module Models
    class FalsePositive < Sequel::Model
      set_allowed_columns :fingerprint, :path, :repository
    end
  end
end
