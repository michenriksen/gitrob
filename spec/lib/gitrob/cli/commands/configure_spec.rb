require "spec_helper"

describe Gitrob::CLI::Commands::Configure do
  def stub_config_file(file_exists=true)
    allow(File).to receive(:exist?)
      .with(configuration_file_path)
      .and_return(file_exists)

    stub_file = double("gitrobrc")
    allow(stub_file).to receive(:write)
      .and_return(true)

    allow(File).to receive(:open)
      .with(configuration_file_path, "w")
      .and_yield(stub_file)
  end

  def stub_overwrite_agreement(result=true)
    allow_any_instance_of(described_class)
      .to receive(:agree_to_overwrite?)
      .and_return(result)
  end

  def stub_config_gathering
    allow_any_instance_of(described_class)
      .to receive(:gather_configuration)
      .and_return(mock_configuration)
  end

  let(:configuration_file_path) do
    File.join(Dir.home, ".gitrobrc")
  end

  let(:options) { Hash.new }
  let(:mock_configuration) do
    {
      :hostname      => "localhost",
      :port          => 5432,
      :username      => "gitrob",
      :password      => "gitrob",
      :database      => "gitrob_test",
      :access_tokens => %w(
        deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
        deadbabedeadbabedeadbabedeadbabedeadbabe
      )
    }
  end

  describe "Initializer" do
    let(:expected_yaml) do
      YAML.dump(
        "sql_connection_uri" =>
          "postgres://username:password@hostname:5432/database",
        "github_access_tokens" => %w(
          deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
          deadbabedeadbabedeadbabedeadbabedeadbabe
        )
      )
    end

    it "outputs informational message" do
      stub_config_file(false)
      stub_overwrite_agreement
      stub_config_gathering
      expect_any_instance_of(described_class)
        .to receive(:info)
        .with("Starting Gitrob configuration wizard")
      capture_stdout do
        described_class.new(options)
      end
    end

    it "writes YAML configuration to file" do
      stub_overwrite_agreement
      expect_any_instance_of(described_class)
        .to receive(:gather_hostname)
        .and_return("hostname")
      expect_any_instance_of(described_class)
        .to receive(:gather_port)
        .and_return(5432)
      expect_any_instance_of(described_class)
        .to receive(:gather_username)
        .and_return("username")
      expect_any_instance_of(described_class)
        .to receive(:gather_password)
        .and_return("password")
      expect_any_instance_of(described_class)
        .to receive(:gather_database)
        .and_return("database")
      expect_any_instance_of(described_class)
        .to receive(:gather_access_tokens)
        .and_return(%w(
          deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
          deadbabedeadbabedeadbabedeadbabedeadbabe
        ))
      spy_file = spy
      expect(spy_file).to receive(:write)
        .with(expected_yaml)
      expect(File).to receive(:open)
        .with(configuration_file_path, "w")
        .and_yield(spy_file)
      capture_stdout do
        described_class.new(options)
      end
    end

    it "outputs an informational task message" do
      stub_config_file
      stub_overwrite_agreement
      stub_config_gathering
      expect_any_instance_of(described_class)
        .to receive(:task)
        .with("Saving configuration to #{configuration_file_path}")
        .and_yield
      capture_stdout do
        described_class.new(options)
      end
    end

    describe "Questions" do
      describe "PostgreSQL hostname" do
        it "asks for PostgreSQL hostname" do
          stub_config_file(false)
          stub_overwrite_agreement
          expect_any_instance_of(HighLine)
            .to receive(:ask)
            .with("Enter PostgreSQL hostname: ")
            .and_return("localhost")
          allow_any_instance_of(described_class)
            .to receive(:gather_port)
          allow_any_instance_of(described_class)
            .to receive(:gather_username)
          allow_any_instance_of(described_class)
            .to receive(:gather_password)
          allow_any_instance_of(described_class)
            .to receive(:gather_database)
          allow_any_instance_of(described_class)
            .to receive(:gather_access_tokens)
          capture_stdout do
            described_class.new(options)
          end
        end

        it "has a default value of localhost" do
          stub_config_file(false)
          stub_overwrite_agreement
          spy_question = spy
          expect(spy_question).to receive(:default=)
            .with("localhost")
          expect_any_instance_of(HighLine)
            .to receive(:ask)
            .and_yield(spy_question)
          allow_any_instance_of(described_class)
            .to receive(:gather_port)
          allow_any_instance_of(described_class)
            .to receive(:gather_username)
          allow_any_instance_of(described_class)
            .to receive(:gather_password)
          allow_any_instance_of(described_class)
            .to receive(:gather_database)
          allow_any_instance_of(described_class)
            .to receive(:gather_access_tokens)
          capture_stdout do
            described_class.new(options)
          end
        end
      end

      describe "PostgreSQL port" do
        it "asks for PostgreSQL port" do
          stub_config_file(false)
          stub_overwrite_agreement
          expect_any_instance_of(HighLine)
            .to receive(:ask)
            .with("Enter PostgreSQL port: |5432| ", Integer)
            .and_return(5432)
          allow_any_instance_of(described_class)
            .to receive(:gather_hostname)
          allow_any_instance_of(described_class)
            .to receive(:gather_username)
          allow_any_instance_of(described_class)
            .to receive(:gather_password)
          allow_any_instance_of(described_class)
            .to receive(:gather_database)
          allow_any_instance_of(described_class)
            .to receive(:gather_access_tokens)
          capture_stdout do
            described_class.new(options)
          end
        end

        it "has a default value of 5432" do
          stub_config_file(false)
          stub_overwrite_agreement
          spy_question = spy
          expect(spy_question).to receive(:default=)
            .with(5432)
          expect_any_instance_of(HighLine)
            .to receive(:ask)
            .and_yield(spy_question)
          allow_any_instance_of(described_class)
            .to receive(:gather_hostname)
          allow_any_instance_of(described_class)
            .to receive(:gather_username)
          allow_any_instance_of(described_class)
            .to receive(:gather_password)
          allow_any_instance_of(described_class)
            .to receive(:gather_database)
          allow_any_instance_of(described_class)
            .to receive(:gather_access_tokens)
          capture_stdout do
            described_class.new(options)
          end
        end

        it "validates that given value is a valid port number" do
          stub_config_file(false)
          stub_overwrite_agreement
          spy_question = spy
          expect(spy_question).to receive(:in=)
            .with(1..65_535)
          expect_any_instance_of(HighLine)
            .to receive(:ask)
            .and_yield(spy_question)
          allow_any_instance_of(described_class)
            .to receive(:gather_hostname)
          allow_any_instance_of(described_class)
            .to receive(:gather_username)
          allow_any_instance_of(described_class)
            .to receive(:gather_password)
          allow_any_instance_of(described_class)
            .to receive(:gather_database)
          allow_any_instance_of(described_class)
            .to receive(:gather_access_tokens)
          capture_stdout do
            described_class.new(options)
          end
        end
      end

      describe "PostgreSQL username" do
        it "asks for PostgreSQL username" do
          stub_config_file(false)
          stub_overwrite_agreement
          expect_any_instance_of(HighLine)
            .to receive(:ask)
            .with("Enter PostgreSQL username: ")
            .and_return("gitrob")
          allow_any_instance_of(described_class)
            .to receive(:gather_hostname)
          allow_any_instance_of(described_class)
            .to receive(:gather_port)
          allow_any_instance_of(described_class)
            .to receive(:gather_password)
          allow_any_instance_of(described_class)
            .to receive(:gather_database)
          allow_any_instance_of(described_class)
            .to receive(:gather_access_tokens)
          capture_stdout do
            described_class.new(options)
          end
        end

        it "has a default value of gitrob" do
          stub_config_file(false)
          stub_overwrite_agreement
          spy_question = spy
          expect(spy_question).to receive(:default=)
            .with("gitrob")
          expect_any_instance_of(HighLine)
            .to receive(:ask)
            .and_yield(spy_question)
          allow_any_instance_of(described_class)
            .to receive(:gather_hostname)
          allow_any_instance_of(described_class)
            .to receive(:gather_port)
          allow_any_instance_of(described_class)
            .to receive(:gather_password)
          allow_any_instance_of(described_class)
            .to receive(:gather_database)
          allow_any_instance_of(described_class)
            .to receive(:gather_access_tokens)
          capture_stdout do
            described_class.new(options)
          end
        end
      end

      describe "PostgreSQL password" do
        it "asks for PostgreSQL password" do
          stub_config_file(false)
          stub_overwrite_agreement
          expect_any_instance_of(HighLine)
            .to receive(:ask)
            .with("Enter PostgreSQL password (masked): ")
            .and_return("gitrob")
          allow_any_instance_of(described_class)
            .to receive(:gather_hostname)
          allow_any_instance_of(described_class)
            .to receive(:gather_port)
          allow_any_instance_of(described_class)
            .to receive(:gather_username)
          allow_any_instance_of(described_class)
            .to receive(:gather_database)
          allow_any_instance_of(described_class)
            .to receive(:gather_access_tokens)
          capture_stdout do
            described_class.new(options)
          end
        end

        it "masks input" do
          stub_config_file(false)
          stub_overwrite_agreement
          spy_question = spy
          expect(spy_question).to receive(:echo=)
            .with("x")
          expect_any_instance_of(HighLine)
            .to receive(:ask)
            .and_yield(spy_question)
          allow_any_instance_of(described_class)
            .to receive(:gather_hostname)
          allow_any_instance_of(described_class)
            .to receive(:gather_port)
          allow_any_instance_of(described_class)
            .to receive(:gather_username)
          allow_any_instance_of(described_class)
            .to receive(:gather_database)
          allow_any_instance_of(described_class)
            .to receive(:gather_access_tokens)
          capture_stdout do
            described_class.new(options)
          end
        end
      end

      describe "PostgreSQL database" do
        it "asks for PostgreSQL database" do
          stub_config_file(false)
          stub_overwrite_agreement
          expect_any_instance_of(HighLine)
            .to receive(:ask)
            .with("Enter PostgreSQL database name: ")
            .and_return("gitrob")
          allow_any_instance_of(described_class)
            .to receive(:gather_hostname)
          allow_any_instance_of(described_class)
            .to receive(:gather_port)
          allow_any_instance_of(described_class)
            .to receive(:gather_username)
          allow_any_instance_of(described_class)
            .to receive(:gather_password)
          allow_any_instance_of(described_class)
            .to receive(:gather_access_tokens)
          capture_stdout do
            described_class.new(options)
          end
        end

        it "has a default value of gitrob" do
          stub_config_file(false)
          stub_overwrite_agreement
          spy_question = spy
          expect(spy_question).to receive(:default=)
            .with("gitrob")
          expect_any_instance_of(HighLine)
            .to receive(:ask)
            .and_yield(spy_question)
          allow_any_instance_of(described_class)
            .to receive(:gather_hostname)
          allow_any_instance_of(described_class)
            .to receive(:gather_port)
          allow_any_instance_of(described_class)
            .to receive(:gather_username)
          allow_any_instance_of(described_class)
            .to receive(:gather_password)
          allow_any_instance_of(described_class)
            .to receive(:gather_access_tokens)
          capture_stdout do
            described_class.new(options)
          end
        end
      end

      describe "GitHub access tokens" do
        it "asks for GitHub access tokens" do
          stub_config_file(false)
          stub_overwrite_agreement
          expect_any_instance_of(HighLine)
            .to receive(:ask)
            .with(
              "Enter GitHub access tokens (blank line to stop):",
              instance_of(Proc)
            )
            .and_return(%w(
              deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
              deadbabedeadbabedeadbabedeadbabedeadbabe
            ))
          allow_any_instance_of(described_class)
            .to receive(:gather_hostname)
          allow_any_instance_of(described_class)
            .to receive(:gather_port)
          allow_any_instance_of(described_class)
            .to receive(:gather_username)
          allow_any_instance_of(described_class)
            .to receive(:gather_password)
          allow_any_instance_of(described_class)
            .to receive(:gather_database)
          capture_stdout do
            described_class.new(options)
          end
        end
      end
    end

    context "when configuration file already exists" do
      it "outputs a warning message" do
        stub_config_file(true)
        stub_config_gathering
        expect_any_instance_of(described_class)
          .to receive(:warn)
          .with("Configuration file already exists\n")
        expect_any_instance_of(HighLine).to receive(:agree)
          .with("Proceed and overwrite existing configuration file? (y/n): ")
        capture_stdout do
          described_class.new(options)
        end
      end

      it "asks if user wants to overwrite it" do
        stub_config_file(true)
        stub_config_gathering
        expect_any_instance_of(HighLine).to receive(:agree)
          .with("Proceed and overwrite existing configuration file? (y/n): ")
        capture_stdout do
          described_class.new(options)
        end
      end

      context "when user agrees to overwrite" do
        it "gathers configuration" do
          stub_config_file(true)
          stub_overwrite_agreement(true)
          expect_any_instance_of(described_class)
            .to receive(:gather_configuration)
            .and_return(mock_configuration)
          capture_stdout do
            described_class.new(options)
          end
        end

        it "saves configuration" do
          stub_config_file(true)
          stub_overwrite_agreement(true)
          stub_config_gathering
          expect_any_instance_of(described_class)
            .to receive(:save_configuration)
            .with(mock_configuration)
          capture_stdout do
            described_class.new(options)
          end
        end
      end

      context "when user does not agree to overwrite" do
        it "does not gather configuration" do
          stub_config_file(true)
          stub_overwrite_agreement(false)
          expect_any_instance_of(described_class)
            .to_not receive(:gather_configuration)
          capture_stdout do
            described_class.new(options)
          end
        end

        it "does not save configuration" do
          stub_config_file(true)
          stub_overwrite_agreement(false)
          stub_config_gathering
          expect_any_instance_of(described_class)
            .to_not receive(:save_configuration)
          capture_stdout do
            described_class.new(options)
          end
        end
      end
    end
  end

  describe ".configured?" do
    context "when configuration file exists" do
      it "returns true" do
        expect(File).to receive(:exist?)
          .with(configuration_file_path)
          .and_return(true)
        expect(described_class.configured?).to be true
      end
    end

    context "when configuration file does not exist" do
      it "returns false" do
        expect(File).to receive(:exist?)
          .with(configuration_file_path)
          .and_return(false)
        expect(described_class.configured?).to be false
      end
    end
  end

  describe ".load_configuration!" do
    let(:mock_configuration) do
      {
        "sql_connection_uri" =>
          "postgres://username:password@hostname:5432/database",
        "github_access_tokens" => %w(
          deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
          deadbabedeadbabedeadbabedeadbabedeadbabe
        )
      }
    end

    it "loads YAML from .gitrobrc" do
      expect(File).to receive(:read)
        .with(configuration_file_path)
        .and_return(YAML.dump(mock_configuration))
      expect(described_class.load_configuration!)
        .to eq(mock_configuration)
    end

    context "when configuration file does not exist" do
      it "raises ConfigurationFileNotFoundError exception" do
        expect(File).to receive(:exist?)
          .with(configuration_file_path)
          .and_return(false)
        expect do
          described_class.load_configuration!
        end.to raise_error(
          Gitrob::CLI::Commands::Configure::ConfigurationFileNotFound
        )
      end
    end

    context "when configuration is not readable" do
      it "raises ConfigurationFileNotFoundReadable exception" do
        expect(File).to receive(:exist?)
          .with(configuration_file_path)
          .and_return(true)
        expect(File).to receive(:readable?)
          .with(configuration_file_path)
          .and_return(false)
        expect do
          described_class.load_configuration!
        end.to raise_error(
          Gitrob::CLI::Commands::Configure::ConfigurationFileNotReadable
        )
      end
    end

    context "when file content is not valid YAML" do
      it "raises ConfigurationFileCorrupt exception" do
        expect(File).to receive(:exist?)
          .with(configuration_file_path)
          .and_return(true)
        expect(File).to receive(:readable?)
          .with(configuration_file_path)
          .and_return(true)
        expect(File).to receive(:read)
          .with(configuration_file_path)
          .and_return("-\n-wat?--")
        expect do
          described_class.load_configuration!
        end.to raise_error(
          Gitrob::CLI::Commands::Configure::ConfigurationFileCorrupt
        )
      end
    end
  end
end
