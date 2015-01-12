module Gitrob
  module Github
    class Blob
      attr_reader :path, :size, :repository

      def initialize(path, size, repository)
        @path, @size, @repository = path, size, repository
      end

      def extension
        File.extname(path)[1..-1]
      end

      def filename
        File.basename(path)
      end

      def dirname
        File.dirname(path)
      end

      def url
        "https://github.com/#{URI.escape(repository.owner)}/#{URI.escape(repository.name)}/blob/master/#{URI.escape(path)}"
      end

      def to_model(organization, repository)
        repository.blobs.new(
          :path           => self.path,
          :filename       => self.filename,
          :extension      => self.extension,
          :size           => self.size,
          :organization   => organization
        )
      end

      def save_to_database!(organization, repository)
        self.to_model(organization, repository).tap { |m| m.save }
      end
    end
  end
end
