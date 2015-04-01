module Gitrob
  module Github
    class Organization
      attr_reader :name, :http_client

      def initialize(name, http_client)
        @name, @http_client = name, http_client
      end

      def display_name
        info['name'].to_s.empty? ? info['login'] : info['name']
      end

      def login
        info['login']
      end

      def website
        info['blog']
      end

      def location
        info['location']
      end

      def email
        info['email']
      end

      def url
        URI::join("#{http_client.github_base_uri}/", "/#{name}")
      end

      def avatar_url
        info['avatar_url']
      end

      def repositories
        @repositories ||= recursive_repositories
      end

      def members
        @members ||= recursive_members
      end

      def to_model
        Gitrob::Organization.new(
          :name       => self.display_name,
          :login      => self.login,
          :website    => self.website,
          :location   => self.location,
          :email      => self.email,
          :avatar_url => self.avatar_url,
          :url        => self.url
        )
      end

      def save_to_database!
        self.to_model.tap { |m| m.save }
      end

    private

      def recursive_members(page = 1)
        members = Array.new
        response = http_client.do_get("/orgs/#{name}/members?page=#{page.to_i}")
        JSON.parse(response.body).each do |member|
          members << User.new(member['login'], http_client)
        end

        if response.headers.include?('link') && response.headers['link'].include?('rel="next"')
          members += recursive_members(page + 1)
        end
        members
      end

      def recursive_repositories(page = 1)
        repositories = Array.new
        response = http_client.do_get("/orgs/#{name}/repos?page=#{page.to_i}")
        JSON.parse(response.body).each do |repo|
          next if repo['fork']
          repositories << Repository.new(name, repo['name'], http_client)
        end

        if response.headers.include?('link') && response.headers['link'].include?('rel="next"')
          repositories += recursive_repositories(page + 1)
        end
        repositories
      end

      def info
        if !@info
          @info = JSON.parse(http_client.do_get("/orgs/#{name}").body)
        end
        @info
      end
    end
  end
end
