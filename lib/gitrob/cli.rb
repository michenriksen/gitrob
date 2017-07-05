module Gitrob
  class QueryLogger < Logger
    def format_message(_severity, _timestamp, _progname, msg)
      "#{msg}\n".cyan
    end
  end

  class CLI < Thor
    HELP_COMMANDS = %w(help h --help -h)
    package_name "Gitrob"

    attr_reader :configuration

    DB_MIGRATIONS_PATH = File.expand_path(
      "../../../db/migrations", __FILE__
    )

    class_option :bind_address,
                 :type    => :string,
                 :banner  => "ADDRESS",
                 :default => "127.0.0.1",
                 :desc    => "Address to bind web server to"
    class_option :port,
                 :type    => :numeric,
                 :default => 9393,
                 :desc    => "Port to run web server on"
    class_option :access_tokens,
                 :type    => :string,
                 :banner  => "TOKENS",
                 :desc    => "Comma-separated list of GitHub API tokens to " \
                             "use instead of what has been configured"
    class_option :color,
                 :type    => :boolean,
                 :default => true,
                 :desc    => "Colorize or don't colorize output"
    class_option :banner,
                 :type    => :boolean,
                 :default => true,
                 :desc    => "Show or don't show Gitrob banner"
    class_option :debug,
                 :type    => :boolean,
                 :default => false,
                 :desc    => "Show or don't show debugging information"

    def initialize(*args)
      super
      Hashie.logger = Logger.new(nil) # Disable warnings from Hashie
      self.class.enable_debugging if options[:debug]
      String.disable_colorization(!options[:color])
      return if help_command?
      banner
      configure unless configured?
      load_configuration
      prepare_database
      prepare_user
    end

    desc "analyze TARGETS", "Analyze one or more organizations or users"
    option :title,
           :type => :string,
           :desc => "Give assessment a custom title"
    option :threads,
           :type    => :numeric,
           :default => 5,
           :desc    => "Number of threads to use"
    option :server,
           :type    => :boolean,
           :default => true,
           :desc    => "Start or don't start web server after assessment"
    option :endpoint,
           :type    => :string,
           :banner  => "URL",
           :default => "https://api.github.com",
           :desc    => "Specify a URL for a custom GitHub Enterprise API"
    option :site,
           :type    => :string,
           :banner  => "URL",
           :default => "https://github.com",
           :desc    => "Specify a URL for a custom GitHub Enterprise site"
    option :verify_ssl,
           :type    => :boolean,
           :default => true,
           :desc    => "Verify or don't verify SSL connection (careful here)"
    # Zendesk - Option to disable / enable org member scan
    option :scan_org_members,
           :type    => :boolean,
           :default => false,
           :desc    => "Options to enable/disable organiztion members scan"
    def analyze(targets)
      accept_tos
      Gitrob::CLI::Commands::Analyze.start(targets, options)
    end

    desc "server", "Start web server"
    def server
      accept_tos
      Gitrob::CLI::Commands::Server.start(options)
    end

    desc "configure", "Start configuration wizard"
    def configure
      Gitrob::CLI::Commands::Configure.start(options)
    end

    desc "banner", "Print Gitrob banner", :hide => true
    def banner
      Gitrob::CLI::Commands::Banner.start(options)
    end

    desc "accept-tos", "Accept Terms Of Use", :hide => true
    def accept_tos
      Gitrob::CLI::Commands::AcceptTermsOfUse.start(options)
    end

    no_commands do
      def help_command?
        !ENV["GITROB_ENV"] == "TEST" &&
          (ARGV.empty? || HELP_COMMANDS.include?(ARGV.first.downcase))
      end

      def configured?
        Gitrob::CLI::Commands::Configure.configured?
      end

      def load_configuration
        self.class.task("Loading configuration...", true) do
          @configuration = Gitrob::CLI::Commands::Configure.load_configuration!
          self.class.configuration = @configuration
        end
      end

      def prepare_database
        self.class.task("Preparing database...", true) do
          Sequel.extension :migration, :core_extensions
          db = Sequel.connect(configuration["sql_connection_uri"])
          Sequel::Migrator.run(db, DB_MIGRATIONS_PATH)
          Sequel::Model.raise_on_save_failure = true
          Sequel::Model.db = db
          Sequel::Model.plugin :validation_helpers
          Sequel::Model.plugin :timestamps
          load_models
        end
      end

      #Zendesk - Create new Gitrob User
      def prepare_user
        @gitrobUser = Gitrob::Models::GitrobUser.all
        if @gitrobUser.count == 0
          username = "gitrob"
          random_string = SecureRandom.base64(75)
          puts "\033[0;31m"
          puts "============================================================"
          puts "Password only generated once. Please save it somewhere safe!"
          puts "Creating new User for Gitrob"
          puts "Username: " + username
          puts "Password: " + random_string
          puts "============================================================"
          puts "\e[0"
          @user = Gitrob::Models::GitrobUser.new
          @user.username = username
          @user.password = random_string
          @user.save       
        end
      end

      def load_models
        require "gitrob/models/assessment"
        require "gitrob/models/github_access_token"
        require "gitrob/models/owner"
        require "gitrob/models/repository"
        require "gitrob/models/blob"
        require "gitrob/models/flag"
        require "gitrob/models/comparison"
        require "gitrob/models/fingerprint"
        require "gitrob/models/gitrob_user"
      end
    end

    def self.info(message)
      output "[*]".light_blue + " #{message}\n"
    end

    def self.task(message, fatal_error=false, &block)
      output "[*]".light_blue + " #{message}"
      yield block
      output " done\n".light_green
    rescue => e
      output " failed\n".light_red
      output_failed_task(e, fatal_error)
    end

    def self.output_failed_task(exception, fatal_error)
      message = "#{exception.class}: #{exception.message}"
      debug exception.backtrace.join("\n")
      if fatal_error
        fatal message
      else
        error message
      end
    end

    def self.warn(message)
      output "[!]".light_yellow + " #{message}\n"
    end

    def self.error(message)
      output "[!]".light_red + " #{message}\n"
    end

    def self.fatal(message)
      output "[!]".light_white.on_red + " #{message}\n"
      exit(1)
    end

    def self.debug(message)
      output "[#]".light_cyan + " #{message}\n" if debugging_enabled?
    end

    def self.output(string)
      print string
    end

    def self.enable_debugging
      @debugging_enabled = true
    end

    def self.disable_debugging
      @debugging_enabled = false
    end

    def self.debugging_enabled? # rubocop:disable Style/TrivialAccessors
      @debugging_enabled
    end

    def self.configuration=(config)
      @config = config
    end

    def self.configuration
      @config
    end
  end
end
