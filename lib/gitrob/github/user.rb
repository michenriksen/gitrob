module Gitrob
  module Github
    class User

      attr_reader :username, :http_client

      def initialize(username, http_client)
        @username, @http_client = username, http_client
      end

      def name
        info['name'] || username
      end

      def email
        info['email']
      end

      def website
        info['blog']
      end

      def location
        info['location']
      end

      def bio
        info['bio']
      end

      def url
        info['html_url']
      end

      def avatar_url
        info['avatar_url']
      end

      def repositories
        @repositories ||= recursive_repositories
      end

      def to_model(organization)
        organization.users.new(
          :username   => self.username,
          :name       => self.name,
          :website    => self.website,
          :location   => self.location,
          :email      => self.email,
          :bio        => self.bio,
          :url        => self.url,
          :avatar_url => self.avatar_url
        )
      end

      def save_to_database!(organization)
        self.to_model(organization).tap { |m| m.save }
      end

    private

      def recursive_repositories(page = 1)
        repositories = Array.new
        response = http_client.do_get("/users/#{username}/repos?page=#{page.to_i}")
        JSON.parse(response.body).each do |repo|
          next if repo['fork']
          repositories << Repository.new(username, repo['name'], http_client)
        end

        if response.headers.include?('link') && response.headers['link'].include?('rel="next"')
          repositories += recursive_repositories(page + 1)
        end
        repositories
      end

      def info
        if !@info
          @info = JSON.parse(http_client.do_get("/users/#{username}").body)
        end
        @info
      end
    end
  end
end
