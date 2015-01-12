module Gitrob
  module Util
    def self.pluralize(count, singular, plural)
      if count.to_i == 1
        "#{count} #{singular}"
      else
        "#{count} #{plural}"
      end
    end
  end
end
