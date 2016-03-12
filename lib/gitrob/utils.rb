module Gitrob
  module Utils
    def self.pluralize(count, singular, plural)
      if count == 1
        "#{count} #{singular}"
      else
        "#{count} #{plural}"
      end
    end

    def self.symbolize_hash_keys(hash)
      symbolized = {}
      hash.each_pair do |k, v|
        symbolized[k.to_sym] = v
      end
      symbolized
    end
  end
end
