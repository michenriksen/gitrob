module Gitrob
  module Github
    class ClientManager
      USER_AGENT = "Gitrob v#{Gitrob::VERSION}"

      attr_reader :clients

      class NoClientsError < StandardError; end

      def initialize(config)
        @config  = config
        @mutex   = Mutex.new
        @clients = []
        config[:access_tokens].each do |token|
          clients << create_client(token)
        end
      end

      def sample
        @mutex.synchronize do
          fail NoClientsError if clients.count.zero?
          clients.sample
        end
      end

      def remove(client)
        @mutex.synchronize do
          clients.delete(client)
        end
      end

      private

      def create_client(access_token)
        ::Github.new(
          :oauth_token     => access_token,
          :endpoint        => @config[:endpoint],
          :site            => @config[:site],
          :ssl             => @config[:ssl],
          :user_agent      => USER_AGENT,
          :auto_pagination => true
        )
      end
    end
  end
end
