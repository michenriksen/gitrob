module Gitrob
  module Models
    class Blob < Sequel::Model
      set_allowed_columns :path, :size, :sha

      SHA_REGEX = /[a-f0-9]{40}/
      TEST_BLOB_INDICATORS = %w(test spec fixture mock stub fake demo sample)
      LARGE_BLOB_THRESHOLD = 102_400

      one_to_many :flags
      many_to_one :repository
      many_to_one :owner
      many_to_one :assessment
      many_to_many :comparisons

      def validate
        super
        validates_presence [:path, :size, :sha]
        validates_format SHA_REGEX, :sha
      end

      def filename
        File.basename(path)
      end

      def extension
        File.extname(path)[1..-1]
      end

      def test_blob?
        TEST_BLOB_INDICATORS.each do |indicator|
          return true if path.downcase.include?(indicator)
        end
        false
      end

      def html_url
        "#{repository.html_url}/blob/#{repository.default_branch}/#{path}"
      end

      def history_html_url
        "#{repository.html_url}/commits/#{repository.default_branch}/#{path}"
      end

      def large?
        size.to_i > LARGE_BLOB_THRESHOLD
      end
    end
  end
end
