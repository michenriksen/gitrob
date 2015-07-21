module Gitrob
  module Github
    class Repository

      attr_reader :owner, :name, :http_client, :operation
      def initialize(owner, name, http_client, operation = 'new')
        @owner, @name, @http_client, @operation = owner, name, http_client, operation
      end

      def contents
        if !@contents
          @contents = []
          response = JSON.parse(http_client.do_get("/repos/#{owner}/#{name}/git/trees/master?recursive=1").body)
          response['tree'].each do |object|
            next unless object['type'] == 'blob'
            @contents << Blob.new(object['path'], object['size'], self)
          end
        end
        @contents
      rescue HttpClient::ClientError => ex
        if ex.status == 409 || ex.status == 404
          @contents = []
        else
          raise ex
        end
      end

      def exists
         operation == 'update'
      end

      def full_name
        [owner, name].join('/')
      end

      def url
        info['html_url']
      end

      def description
        info['description']
      end

      def website
        info['homepage']
      end

      def to_model(organization, user = nil)
        Gitrob::Repo.new(
          :name         => self.name,
          :owner_name   => self.owner,
          :description  => self.description,
          :website      => self.website,
          :url          => self.url,
          :organization => organization,
          :user         => user
        )
      end

      def save_to_database!(organization, user = nil)
        self.to_model(organization, user).tap { |m| m.save }
      rescue DataMapper::SaveFailureError => e
	Gitrob::status("ERROR")
        puts e.resource.errors.inspect
      end

    private

      def info
        if !@info
          @info = JSON.parse(http_client.do_get("/repos/#{owner}/#{name}").body)
        end
        @info
      end
    end
  end
end
