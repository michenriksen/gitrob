module Gitrob
  module Github
    class User

      attr_reader :username, :http_client, :operation

      def initialize(username, http_client, operation = 'new')
        @username, @http_client, @operation = username, http_client, operation
      end

      def exists
        operation == 'update'
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

      def repositories(operation = nil, org_id = nil)
        @repositories ||= recursive_repositories(operation, org_id)
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

      def recursive_repositories(operation, org_id, page = 1)
        repositories = Array.new
        response = http_client.do_get("/users/#{username}/repos?page=#{page.to_i}")
        JSON.parse(response.body).each do |repo|
          next if repo['fork']

          if operation == 'update'
            currentRepo = Gitrob::Organization.get(org_id).users.first(:username => username).repos.first(:name => repo['name'])
            #Gitrob::status("currentRepo: #{currentRepo}")
            op = 'new'

            if !currentRepo.nil?
              op = operation
              lastUpdate = currentRepo.last_update.strftime("%FT%TZ")
              #Gitrob::status("#{repo['name']} LAST UPDATED: #{lastUpdate}")
              repoSize = http_client.do_get("/repos/#{username}/#{repo['name']}/stats/commit_activity")
              next if repoSize.body.nil?

              repoObj = http_client.do_get("/repos/#{username}/#{repo['name']}/commits?since=#{lastUpdate}")
             # Gitrob::status("#{repoObj.body}")
              next if repoObj.body == '[]'
            end
          end
          #Gitrob::status("ADDED REPO: #{repo['name']}")
          repositories << Repository.new(username, repo['name'], http_client, op)
        end

        if response.headers.include?('link') && response.headers['link'].include?('rel="next"')
          repositories += recursive_repositories(operation, org_id, page + 1)
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
