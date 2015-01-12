module Gitrob
  module Github
    class HttpClient
      include HTTParty
      base_uri 'https://api.github.com'

      class HttpError < StandardError; end
      class ConnectionError < HttpError; end

      class RequestError < HttpError
        attr_reader :status, :body
        def initialize(method, path, status, body, options)
          @status = status
          @body   = body
          super("#{method} to #{path} returned status #{status} - options: #{options.inspect}")
        end
      end

      class ClientError < RequestError; end
      class ServerError < RequestError; end

      class UnhandledError < StandardError; end

      class AccessTokenError < StandardError; end
      class MissingAccessTokensError < AccessTokenError; end
      class AccessTokensDepletedError < AccessTokenError; end

      DEFAULT_TIMEOUT = 0.5 #seconds
      DEFAULT_RETRIES = 3

      Response = Struct.new(:status, :headers, :body)

      RETRIABLE_EXCEPTIONS = [
        ServerError,
        AccessTokenError,
        Timeout::Error,
        Errno::ETIMEDOUT,
        Errno::ECONNRESET,
        Errno::ECONNREFUSED,
        Errno::ENETUNREACH,
        Errno::EHOSTUNREACH,
        EOFError
      ]

      def initialize(options)
        @config = {
          :timeout => DEFAULT_TIMEOUT,
          :retries => DEFAULT_RETRIES
        }.merge(options)
        raise MissingAccessTokensErrors.new("No access tokens given") unless @config[:access_tokens]
        default_timeout = @config[:timeout]
      end

      def do_get(path, params=nil, options={})
        do_request(:get, path, {:query => params}.merge(options))
      end

      def do_post(path, params=nil, options={})
        do_request(:post, path, {:query => params}.merge(options))
      end

      def do_put(path, params=nil, options={})
        do_request(:put, path, {:query => params}.merge(options))
      end

      def do_delete(path, params=nil, options={})
        do_request(:delete, path, {:query => params}.merge(options))
      end

    private

      def do_request(method, path, options)
        with_retries do
          access_token = get_access_token!
          response     = self.class.send(method, path, {
            :headers => {
              'Authorization' => "token #{access_token}",
              'User-Agent'    => "Gitrob v#{Gitrob::VERSION}"
            }
          }.merge(options))
          handle_possible_error!(method, path, response, options, access_token)
          Response.new(response.code, response.headers, response.body)
        end
      end

      def with_retries(&block)
        tries = @config[:retries]
        yield
      rescue *RETRIABLE_EXCEPTIONS => ex
        if (tries -= 1) > 0
          sleep 0.2
          retry
        else
          raise ex
        end
      end

      def handle_possible_error!(method, path, response, options, access_token)
        if access_token_rate_limited?(response) || access_token_unauthorized?(response)
          access_tokens.delete(access_token)
          raise AccessTokenError
        elsif response.code >= 500
          raise ServerError.new(method, path, response.code, response.body, options)
        elsif response.code >= 400
          raise ClientError.new(method, path, response.code, response.body, options)
        end
      end

      def access_token_rate_limited?(response)
        response.code == 403 && response.headers['X-RateLimit-Remaining'].to_i.zero?
      end

      def access_token_unauthorized?(response)
        response.code == 401
      end

      def get_access_token!
        raise AccessTokensDepletedError.new("Rate limit on all access tokens has been used up") if access_tokens.count.zero?
        access_tokens.sample
      end

      def access_tokens
        @config[:access_tokens]
      end
    end
  end
end
