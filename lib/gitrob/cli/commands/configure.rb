require "uri"

module Gitrob
  class CLI
    module Commands
      class Configure < Gitrob::CLI::Command
        CONFIGURATION_FILE_PATH = File.join(Dir.home, ".gitrobrc")

        class ConfigurationError < StandardError; end
        class ConfigurationFileNotFound < ConfigurationError; end
        class ConfigurationFileNotReadable < ConfigurationError; end
        class ConfigurationFileCorrupt < ConfigurationError; end

        def initialize(options)
          @options = options
          info("Starting Gitrob configuration wizard")
          return unless agree_to_overwrite?
          config = gather_configuration
          task("Saving configuration to #{CONFIGURATION_FILE_PATH}") do
            save_configuration(config)
          end
        end

        def self.configured?
          File.exist?(CONFIGURATION_FILE_PATH)
        end

        def self.load_configuration!
          fail ConfigurationFileNotFound \
            unless File.exist?(CONFIGURATION_FILE_PATH)
          fail ConfigurationFileNotReadable \
            unless File.readable?(CONFIGURATION_FILE_PATH)
          YAML.load(File.read(CONFIGURATION_FILE_PATH))
        rescue Psych::SyntaxError
          raise ConfigurationFileCorrupt
        end

        private

        def agree_to_overwrite?
          return true unless self.class.configured?
          warn("Configuration file already exists\n")
          agree(
            "Proceed and overwrite existing configuration file? (y/n): ")
        end

        def gather_configuration
          {
            :hostname      => gather_hostname,
            :port          => gather_port,
            :username      => gather_username,
            :password      => gather_password,
            :database      => gather_database,
            :access_tokens => gather_access_tokens
          }
        end

        def gather_hostname
          ask("Enter PostgreSQL hostname: ") do |q|
            q.default = "localhost"
          end
        end

        def gather_port
          ask("Enter PostgreSQL port: |5432| ", Integer) do |q|
            q.default = 5432
            q.in = 1..65_535
          end
        end

        def gather_username
          ask("Enter PostgreSQL username: ") do |q|
            q.default = "gitrob"
          end
        end

        def gather_password
          ask("Enter PostgreSQL password (masked): ") do |q|
            q.echo = "x"
          end
        end

        def gather_database
          ask("Enter PostgreSQL database name: ") do |q|
            q.default = "gitrob"
          end
        end

        def gather_access_tokens
          tokens = []
          while tokens.uniq.empty?
            tokens = ask("Enter GitHub access tokens (blank line to stop):",
                         ->(ans) { ans =~ /[a-f0-9]{40}/ ? ans : nil }) do |q|
                           q.gather = ""
                         end
          end
          tokens
        end

        def save_configuration(config)
          File.open(CONFIGURATION_FILE_PATH, "w") do |file|
            file.write(build_yaml(config))
          end
        end

        def make_connection_uri(username, password, hostname, port, database)
          str = "postgres://#{username}:#{password}@#{hostname}:#{port}/#{database}"
          URI::encode(str)
        end

        def build_yaml(config)
          YAML.dump(
            "sql_connection_uri" => make_connection_uri(
              config[:username],
              config[:password],
              config[:hostname],
              config[:port],
              config[:database]
            ),
            "github_access_tokens" => config[:access_tokens]
          )
        end
      end
    end
  end
end
