require "simplecov"
SimpleCov.start do
  add_filter "spec/"
  add_group "Commands", "lib/gitrob/cli/commands"
  add_group "Models", "models"
end

GITROB_ENV="test"

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "factory_girl"
require "faker"
require "awesome_print"
require "webmock/rspec"
require "gitrob"
require "#{File.dirname(__FILE__)}/helpers"
require "#{File.dirname(__FILE__)}/support/fake_github"

String.disable_colorization(true)

SQL_CONNECTION_URI = "postgres://gitrob:gitrob@localhost:5432/gitrob_test"
DB_MIGRATIONS_PATH = File.expand_path("../../db/migrations", __FILE__)

Sequel.extension :migration, :core_extensions
DB = Sequel.connect(SQL_CONNECTION_URI)
Sequel::Migrator.run(DB, DB_MIGRATIONS_PATH)
Sequel::Model.db = DB
Sequel::Model.plugin :validation_helpers, :timestamps

require "gitrob/models/assessment"
require "gitrob/models/github_access_token"
require "gitrob/models/owner"
require "gitrob/models/repository"
require "gitrob/models/blob"
require "gitrob/models/flag"

RSpec.configure do |config|
  config.include Helpers

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.before(:suite) do
    FactoryGirl.reload
    DB.transaction(:rollback => :always, :auto_savepoint => true) do
      FactoryGirl.lint
    end
  end

  config.around(:each) do |example|
    stub_request(:any, /github.com/).to_rack(FakeGitHub)
    DB.transaction(:rollback => :always, :auto_savepoint => true) do
      example.run
    end
  end

  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = "documentation"
  end

  config.include FactoryGirl::Syntax::Methods
end

class FakeThreadPool
  def process
    yield
  end
end
