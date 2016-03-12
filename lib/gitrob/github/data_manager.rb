module Gitrob
  module Github
    class DataManager
      attr_reader :client_manager,
                  :unknown_logins,
                  :owners,
                  :repositories

      def initialize(logins, client_manager)
        @logins                  = logins
        @client_manager          = client_manager
        @unknown_logins          = []
        @owners                  = []
        @repositories            = []
        @repositories_for_owners = {}
        @mutex                   = Mutex.new
      end

      def gather_owners(thread_pool)
        @logins.each do |login|
          next unless owner = get_owner(login)
          @owners << owner
          @repositories_for_owners[owner["login"]] = []
          next unless owner["type"] == "Organization"
          get_members(owner, thread_pool) if owner["type"] == "Organization"
        end
        @owners = @owners.uniq { |o| o["login"] }
      end

      def gather_repositories(thread_pool)
        owners.each do |owner|
          thread_pool.process do
            repositories = get_repositories(owner)
            with_mutex do
              save_repositories(owner, repositories)
            end
            yield owner, repositories if block_given?
          end
        end
      end

      def repositories_for_owner(owner)
        @repositories_for_owners[owner["login"]]
      end

      def blobs_for_repository(repository)
        get_blobs(repository)
      rescue ::Github::Error::Forbidden => e
        # Hidden GitHub feature?
        raise e unless e.message.include?("403 Repository access blocked")
        []
      rescue ::Github::Error::NotFound
        []
      rescue ::Github::Error::ServiceError => e
        raise e unless e.message.include?("409 Git Repository is empty")
        []
      end

      private

      def get_owner(login)
        github_client do |client|
          client.users.get(:user => login)
        end
      rescue ::Github::Error::NotFound
        @unknown_logins << login
        nil
      end

      def get_members(org, thread_pool)
        github_client do |client|
          client.orgs.members.list(:org_name => org["login"]) do |owner|
            thread_pool.process do
              owner = get_owner(owner["login"])
              with_mutex do
                @owners << owner
                @repositories_for_owners[owner["login"]] = []
              end
            end
          end
        end
      end

      def get_repositories(owner)
        github_client do |client|
          client.repos.list(
            :user => owner["login"]).reject { |r| r["fork"] }
        end
      end

      def get_blobs(repository)
        github_client do |client|
          client.get_request(
            "repos/#{repository[:full_name]}/git/trees/" \
            "#{repository[:default_branch]}",
            ::Github::ParamsHash.new(:recursive => 1))["tree"]
            .reject { |b| b["type"] != "blob" }
        end
      end

      def github_client
        client = @client_manager.sample
        yield client
      rescue ::Github::Error::Forbidden => e
        raise e unless e.message.include?("API rate limit exceeded")
        @client_manager.remove(client)
      rescue ::Github::Error::Unauthorized
        @client_manager.remove(client)
      end

      def save_repositories(owner, repositories)
        @repositories += repositories
        @repositories_for_owners[owner["login"]] = repositories
      end

      def with_mutex
        @mutex.synchronize { yield }
      end
    end
  end
end
