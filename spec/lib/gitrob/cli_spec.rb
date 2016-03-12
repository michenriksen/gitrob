require "spec_helper"

# This is horrible...
# I can't make Thor shut up without
# monkey patching puts >:(
#
# TODO: Find a better solution
module Kernel
  def puts(_string)
  end
end

describe Gitrob::CLI do
  def stub_database_preparation
    capture_stdout do
      stub_connection = double("connection")
      allow(stub_connection).to receive(:schema_and_table)
      allow(stub_connection).to receive(:from)
      allow(stub_connection).to receive(:create_table?)
      allow(Sequel).to receive(:connect)
        .and_return(stub_connection)
      allow(Sequel).to receive(:extension)
      allow(Sequel::Migrator).to receive(:run)
      allow(Sequel::Model).to receive(:db=)
      allow(Sequel::Model).to receive(:plugin)
      allow(allow_any_instance_of(described_class))
        .to receive(:load_models)
      allow(described_class)
        .to receive(:fatal)
    end
  end

  describe "Class options" do
    let(:class_options) { described_class.class_options }

    it "has a bind-address class option" do
      expect(class_options).to have_key(:bind_address)
    end

    it "has a port class option" do
      expect(class_options).to have_key(:port)
    end

    it "has an access-tokens class option" do
      expect(class_options).to have_key(:access_tokens)
    end

    it "has a color class option" do
      expect(class_options).to have_key(:color)
    end

    it "has a banner class option" do
      expect(class_options).to have_key(:banner)
    end

    it "has a debug class option" do
      expect(class_options).to have_key(:debug)
    end

    describe "bind_address" do
      subject { class_options[:bind_address] }

      it "has a name of bind_address" do
        expect(subject.name).to eq("bind_address")
      end

      it "has a type of string" do
        expect(subject.type).to eq(:string)
      end

      it "is optional" do
        expect(subject.required).to be false
      end

      it "has a default value of 127.0.0.1" do
        expect(subject.default).to eq("127.0.0.1")
      end

      it "has a description" do
        expect(subject.description).to eq("Address to bind web server to")
      end

      it "has a banner" do
        expect(subject.banner).to eq("ADDRESS")
      end
    end

    describe "port" do
      subject { class_options[:port] }

      it "has a name of port" do
        expect(subject.name).to eq("port")
      end

      it "has a type of numeric" do
        expect(subject.type).to eq(:numeric)
      end

      it "is optional" do
        expect(subject.required).to be false
      end

      it "has a default value of 9393" do
        expect(subject.default).to eq(9393)
      end

      it "has a description" do
        expect(subject.description).to eq("Port to run web server on")
      end
    end

    describe "access-tokens" do
      subject { class_options[:access_tokens] }

      it "has a name of access_tokens" do
        expect(subject.name).to eq("access_tokens")
      end

      it "has a type of array" do
        expect(subject.type).to eq(:array)
      end

      it "is optional" do
        expect(subject.required).to be false
      end

      it "has no default value" do
        expect(subject.default).to be nil
      end

      it "has a description" do
        expect(subject.description)
          .to eq("GitHub API tokens to use " \
                 "instead of what has been configured")
      end

      it "has a banner" do
        expect(subject.banner).to eq("TOKENS")
      end
    end

    describe "color" do
      subject { class_options[:color] }

      it "has a name of color" do
        expect(subject.name).to eq("color")
      end

      it "has a type of boolean" do
        expect(subject.type).to eq(:boolean)
      end

      it "is optional" do
        expect(subject.required).to be false
      end

      it "has a default value of true" do
        expect(subject.default).to be true
      end

      it "has a description" do
        expect(subject.description).to eq("Colorize or don't colorize output")
      end
    end

    describe "banner" do
      subject { class_options[:banner] }

      it "has a namer of banner" do
        expect(subject.name).to eq("banner")
      end

      it "has a type of boolean" do
        expect(subject.type).to eq(:boolean)
      end

      it "is optional" do
        expect(subject.required).to be false
      end

      it "has a default value of true" do
        expect(subject.default).to be true
      end

      it "has a description" do
        expect(subject.description).to eq("Show or don't show Gitrob banner")
      end
    end

    describe "debug" do
      subject { class_options[:debug] }

      it "has a namer of debug" do
        expect(subject.name).to eq("debug")
      end

      it "has a type of boolean" do
        expect(subject.type).to eq(:boolean)
      end

      it "is optional" do
        expect(subject.required).to be false
      end

      it "has a default value of false" do
        expect(subject.default).to be false
      end

      it "has a description" do
        expect(subject.description)
          .to eq("Show or don't show debugging information")
      end
    end
  end

  describe "Commands" do
    let(:commands) { described_class.commands }

    it "has an analyze command" do
      expect(commands).to have_key("analyze")
    end

    it "has a server command" do
      expect(commands).to have_key("server")
    end

    it "has a configure command" do
      expect(commands).to have_key("configure")
    end

    it "has a banner command" do
      expect(commands).to have_key("banner")
    end

    describe "analyze" do
      subject { commands["analyze"] }

      it "has a name of analyze" do
        expect(subject.name).to eq("analyze")
      end

      it "has a description" do
        expect(subject.description)
          .to eq("Analyze one or more organizations or users")
      end

      it "has a usage description" do
        expect(subject.usage).to eq("analyze TARGETS")
      end

      it "is not a hidden command" do
        expect(subject).to_not be_a(Thor::HiddenCommand)
      end

      it "requires acceptance of Terms Of Use" do
        stub_database_preparation
        allow(Gitrob::CLI::Commands::Analyze).to receive(:start)
        cli = nil
        capture_stdout do
          cli = described_class.new
        end
        capture_stdout do
          expect(cli).to receive(:accept_tos)
          subject.run(cli, "test")
        end
      end

      it "calls Gitrob::CLI::Commands::Analyze" do
        stub_database_preparation
        expect(Gitrob::CLI::Commands::Analyze)
          .to receive(:start).with("test", kind_of(Hash))
        capture_stdout do
          allow_any_instance_of(described_class)
            .to receive(:accept_tos)
          subject.run(described_class.new, "test")
        end
      end

      describe "Options" do
        let(:options) { subject.options }

        it "has a title option" do
          expect(options).to have_key(:title)
        end

        it "has a threads option" do
          expect(options).to have_key(:threads)
        end

        it "has a server option" do
          expect(options).to have_key(:server)
        end

        it "has an endpoint option" do
          expect(options).to have_key(:endpoint)
        end

        it "has a site option" do
          expect(options).to have_key(:site)
        end

        it "has a verify_ssl option" do
          expect(options).to have_key(:verify_ssl)
        end

        describe "title" do
          # Using `subject` here courses a recursive method call...
          let(:option) { options[:title] }

          it "has a type of string" do
            expect(option.type).to eq(:string)
          end

          it "has a description" do
            expect(option.description).to eq("Give assessment a custom title")
          end

          it "is optional" do
            expect(option.required).to be false
          end

          it "has no default value" do
            expect(option.default).to be nil
          end
        end

        describe "threads" do
          # Using `subject` here courses a recursive method call...
          let(:option) { options[:threads] }

          it "has a type of numeric" do
            expect(option.type).to eq(:numeric)
          end

          it "has a description" do
            expect(option.description).to eq("Number of threads to use")
          end

          it "is optional" do
            expect(option.required).to be false
          end

          it "has a default value of 5" do
            expect(option.default).to eq(5)
          end
        end

        describe "server" do
          # Using `subject` here courses a recursive method call...
          let(:option) { options[:server] }

          it "has a type of boolean" do
            expect(option.type).to eq(:boolean)
          end

          it "has a description" do
            expect(option.description)
              .to eq("Start or don't start web server after assessment")
          end

          it "is optional" do
            expect(option.required).to be false
          end

          it "has a default value of true" do
            expect(option.default).to be true
          end
        end

        describe "endpoint" do
          # Using `subject` here courses a recursive method call...
          let(:option) { options[:endpoint] }

          it "has a type of string" do
            expect(option.type).to eq(:string)
          end

          it "has a description" do
            expect(option.description)
              .to eq("Specify a URL for a custom GitHub Enterprise API")
          end

          it "has a banner" do
            expect(option.banner).to eq("URL")
          end

          it "is optional" do
            expect(option.required).to be false
          end

          it "has a default value of https://api.github.com" do
            expect(option.default).to eq("https://api.github.com")
          end
        end

        describe "site" do
          # Using `subject` here courses a recursive method call...
          let(:option) { options[:site] }

          it "has a type of string" do
            expect(option.type).to eq(:string)
          end

          it "has a description" do
            expect(option.description)
              .to eq("Specify a URL for a custom GitHub Enterprise site")
          end

          it "has a banner" do
            expect(option.banner).to eq("URL")
          end

          it "is optional" do
            expect(option.required).to be false
          end

          it "has a default value of https://github.com" do
            expect(option.default).to eq("https://github.com")
          end
        end

        describe "verify_ssl" do
          # Using `subject` here courses a recursive method call...
          let(:option) { options[:verify_ssl] }

          it "has a type of boolean" do
            expect(option.type).to eq(:boolean)
          end

          it "has a description" do
            expect(option.description)
              .to eq("Verify or don't verify SSL connection (careful here)")
          end

          it "is optional" do
            expect(option.required).to be false
          end

          it "has a default value of true" do
            expect(option.default).to be true
          end
        end
      end
    end

    describe "server" do
      subject { commands["server"] }

      it "has a name of server" do
        expect(subject.name).to eq("server")
      end

      it "has a description" do
        expect(subject.description).to eq("Start web server")
      end

      it "is not a hidden command" do
        expect(subject).to_not be_a(Thor::HiddenCommand)
      end

      it "requires acceptance of Terms Of Use" do
        stub_database_preparation
        allow(Gitrob::CLI::Commands::Server)
          .to receive(:start).with(kind_of(Hash))
        cli = nil
        capture_stdout do
          cli = described_class.new
        end
        expect(cli).to receive(:accept_tos)
        capture_stdout do
          subject.run(cli)
        end
      end

      it "calls Gitrob::CLI::Commands::Server" do
        stub_database_preparation
        expect(Gitrob::CLI::Commands::Server)
          .to receive(:start).with(kind_of(Hash))
        capture_stdout do
          allow_any_instance_of(described_class)
            .to receive(:accept_tos)
          subject.run(described_class.new)
        end
      end
    end

    describe "configure" do
      subject { commands["configure"] }

      it "has a name of configure" do
        expect(subject.name).to eq("configure")
      end

      it "has a description" do
        expect(subject.description).to eq("Start configuration wizard")
      end

      it "is not a hidden command" do
        expect(subject).to_not be_a(Thor::HiddenCommand)
      end

      it "calls Gitrob::CLI::Commands::Configure" do
        stub_database_preparation
        # Called twice because command is also envoked by initializer
        expect(Gitrob::CLI::Commands::Configure)
          .to receive(:start).with(kind_of(Hash))
        capture_stdout do
          subject.run(described_class.new)
        end
      end
    end

    describe "banner" do
      subject { commands["banner"] }

      it "has a name of banner" do
        expect(subject.name).to eq("banner")
      end

      it "has a description" do
        expect(subject.description).to eq("Print Gitrob banner")
      end

      it "is a hidden command" do
        expect(subject).to be_a(Thor::HiddenCommand)
      end

      it "calls Gitrob::CLI::Commands::Banner" do
        stub_database_preparation
        # Called twice because command is also envoked by initializer
        expect(Gitrob::CLI::Commands::Banner).to receive(:start).twice
        capture_stdout do
          subject.run(described_class.new)
        end
      end
    end

    describe "accept_tos" do
      subject { commands["accept_tos"] }

      it "has a name of accept-tos" do
        expect(subject.name).to eq("accept_tos")
      end

      it "has a description" do
        expect(subject.description).to eq("Accept Terms Of Use")
      end

      it "is a hidden command" do
        expect(subject).to be_a(Thor::HiddenCommand)
      end

      it "calls Gitrob::CLI::Commands::AcceptTermsOfUse" do
        stub_database_preparation
        expect(Gitrob::CLI::Commands::AcceptTermsOfUse).to receive(:start)
        capture_stdout do
          subject.run(described_class.new)
        end
      end
    end
  end

  describe "Initializer" do
    let(:configuration) do
      {
        "sql_connection_uri" =>
          "postgres://username:password@hostname:5432/database",
        "github_access_tokens" => %w(
          deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
          deadbabedeadbabedeadbabedeadbabedeadbabe
        )
      }
    end

    let(:migrations_path) do
      File.expand_path("../../../../db/migrations", __FILE__)
    end

    it "calls banner command" do
      capture_stdout do
        stub_database_preparation
        expect_any_instance_of(Gitrob::CLI).to receive(:banner)
        described_class.new
      end
    end

    it "loads configuration" do
      expect(Gitrob::CLI::Commands::Configure)
        .to receive(:load_configuration!)
        .and_return(configuration)
      capture_stdout do
        stub_database_preparation
        allow_any_instance_of(described_class)
          .to receive(:prepare_database)
        cli = described_class.new
        expect(cli.configuration).to eq(configuration)
      end
    end

    it "sets up database connection" do
      expect(Sequel).to receive(:connect)
        .with("postgres://username:password@hostname:5432/database")
      capture_stdout do
        stub_database_preparation
        expect(described_class)
          .to receive(:task)
          .with("Preparing database...", true)
          .and_yield
        allow_any_instance_of(described_class)
          .to receive(:load_configuration)
        allow_any_instance_of(described_class)
          .to receive(:configuration)
          .and_return(configuration)
        described_class.new
      end
    end

    it "loads ORM extensions" do
      stub_database_preparation
      expect(Sequel).to receive(:extension)
        .with(:migration, :core_extensions)
      allow(Gitrob::CLI::Commands::Configure)
        .to receive(:load_configuration!)
        .and_return(configuration)
      capture_stdout do
        described_class.new
      end
    end

    it "runs database migrations" do
      stub_database_preparation
      expect(Sequel::Migrator).to receive(:run)
        .with(anything, migrations_path)
      allow(Gitrob::CLI::Commands::Configure)
        .to receive(:load_configuration!)
        .and_return(configuration)
      capture_stdout do
        described_class.new
      end
    end

    context "when ~/.gitrobrc does not exist" do
      it "calls configure command" do
        stub_database_preparation
        expect(File)
          .to receive(:exist?).twice
          .with(File.join(Dir.home, ".gitrobrc"))
          .and_return(false)

        capture_stdout do
          expect_any_instance_of(Gitrob::CLI).to receive(:configure)
          described_class.new
        end
      end
    end

    context "when ~/.gitrobrc exists" do
      it "does not call configure command" do
        stub_database_preparation
        expect(File)
          .to receive(:exist?).twice
          .with(File.join(Dir.home, ".gitrobrc"))
          .and_return(true)

        capture_stdout do
          expect_any_instance_of(Gitrob::CLI).not_to receive(:configure)
          described_class.new
        end
      end
    end
  end

  describe "Message printing" do
    describe ".info" do
      it "outputs a message with a blue symbol prefixed" do
        expect(described_class).to receive(:output)
          .with("[*]".light_blue + " This is an informational message\n")
        described_class.info("This is an informational message")
      end
    end

    describe ".task" do
      it "outputs message with a blue symbol prefixed" do
        expect(described_class).to receive(:output)
          .with("[*]".light_blue + " This is a task")
        allow(described_class).to receive(:output)
          .with(" done\n".light_green)
        described_class.task("This is a task") {}
      end

      it "yields control to a block" do
        capture_stdout do
          expect do |b|
            described_class.task("Test", &b)
          end.to yield_control
        end
      end

      context "when block does not raise errors" do
        it "appends done to message in green" do
          expect(described_class).to receive(:output)
            .with("[*]".light_blue + " This is a task")
          expect(described_class).to receive(:output)
            .with(" done\n".light_green)
          described_class.task("This is a task") {}
        end
      end

      context "when block raises an error" do
        it "appends failed to message in red" do
          expect(described_class).to receive(:output)
            .with("[*]".light_blue + " This is a task")
          expect(described_class).to receive(:output)
            .with(" failed\n".light_red)
          allow(described_class).to receive(:error)
          described_class.task("This is a task") do
            fail "Uh oh!"
          end
        end

        it "prints out exception details as an error" do
          expect(described_class).to receive(:error)
            .with("RuntimeError: Uh oh!")
          capture_stdout do
            described_class.task("This is a task") do
              fail "Uh oh!"
            end
          end
        end

        context "When task is set to fatal" do
          it "prints out exception details as a fatal error" do
            expect(described_class).to receive(:fatal)
              .with("RuntimeError: Uh oh!")
            capture_stdout do
              described_class.task("This is a task", true) do
                fail "Uh oh!"
              end
            end
          end
        end
      end

      describe ".output" do
        it "calls print with given string" do
          output = capture_stdout do
            described_class.output("This is a message")
          end
          expect(output).to eq("This is a message")
        end
      end
    end

    describe ".warn" do
      it "outputs a message with a yellow symbol prefixed" do
        expect(described_class).to receive(:output)
          .with("[!]".light_yellow + " This is a warning message\n")
        described_class.warn("This is a warning message")
      end
    end

    describe ".error" do
      it "outputs a message with a red symbol prefixed" do
        expect(described_class).to receive(:output)
          .with("[!]".light_red + " This is an error message\n")
        described_class.error("This is an error message")
      end
    end

    describe ".fatal" do
      it "outputs a message with a white-on-red symbol prefixed and exits" do
        expect(described_class).to receive(:output)
          .with("[!]".light_white.on_red + " Warp Core Breach!\n")
        expect do
          described_class.fatal("Warp Core Breach!")
        end.to raise_error(SystemExit)
      end
    end
  end

  describe ".debugging_enabled?" do
    context "when debugging is enabled" do
      it "returns true" do
        described_class.enable_debugging
        expect(described_class.debugging_enabled?).to be true
      end
    end

    context "when debugging is disabled" do
      it "returns false" do
        described_class.disable_debugging
        expect(described_class.debugging_enabled?).to be false
      end
    end
  end

  describe ".configuration" do
    it "returns configuration" do
      config = double("configuration")
      described_class.configuration = config
      expect(described_class.configuration).to eq(config)
    end
  end
end
