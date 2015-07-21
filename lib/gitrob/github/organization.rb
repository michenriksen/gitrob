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
        "https://github.com/#{name}"
      end

      def avatar_url
        info['avatar_url']
      end

      def repositories(operation = nil, org_id = nil)
        @repositories ||= recursive_repositories(operation, org_id)
      end

      def members(operation = nil, org_id = nil)
        @members ||= recursive_members(operation, org_id)
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

      def recursive_members(operation, org_id, page = 1)
        members = Array.new
        response = http_client.do_get("/orgs/#{name}/members?page=#{page.to_i}")
        JSON.parse(response.body).each do |member|
          if operation == 'update'
            currentMember = Gitrob::Organization.get(org_id).users.first(:username => member['login'])
            op = 'new'

            if !currentMember.nil?
              op = operation
            end
          end

          members << User.new(member['login'], http_client, op)
        end

        if response.headers.include?('link') && response.headers['link'].include?('rel="next"')
          members += recursive_members(operation, org_id, page + 1)
        end
        members
      end

      def recursive_repositories(operation, org_id, page = 1)
        repositories = Array.new
        response = http_client.do_get("/orgs/#{name}/repos?page=#{page.to_i}")
        JSON.parse(response.body).each do |repo|
          next if repo['fork']

          if operation == 'update'
            currentRepo = Gitrob::Organization.get(org_id).repos.first(:name => repo['name'])
            op = 'new'

            if !currentRepo.nil?
              op = operation
              lastUpdate = currentRepo.last_update.strftime("%FT%TZ")
              #Gitrob::status("#{repo['name']} LAST UPDATED: #{lastUpdate}")
              repoSize = http_client.do_get("/repos/#{name}/#{repo['name']}/stats/commit_activity")
              next if repoSize.body.nil?

              repoObj = http_client.do_get("/repos/#{name}/#{repo['name']}/commits?since=#{lastUpdate}")
              #Gitrob::status("#{repoObj.body}")
              next if repoObj.body == '[]'
            end
          end

          repositories << Repository.new(name, repo['name'], http_client, op)
        end

        if response.headers.include?('link') && response.headers['link'].include?('rel="next"')
          repositories += recursive_repositories(operation, org_id, page + 1)
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
