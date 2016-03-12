require "gitrob/cli/commands/analyze/gathering"
require "gitrob/cli/commands/analyze/analysis"

module Gitrob
  class CLI
    module Commands
      class Analyze < Gitrob::CLI::Command
        include Gathering
        include Analysis

        def initialize(targets, options)
          Thread.abort_on_exception = true
          @options = options
          @targets = targets.split(",").map(&:strip).uniq
          load_signatures!
          create_database_assessment
          gather_owners
          gather_repositories
          analyze_repositories
          @db_assessment.finished = true
          @db_assessment.save
          start_web_server
        end

        private

        def create_database_assessment
          @db_assessment = Gitrob::Models::Assessment.create(
            :endpoint   => @options[:endpoint],
            :site       => @options[:site],
            :verify_ssl => @options[:verify_ssl],
            :finished   => false
          )
          github_access_tokens.each do |access_token|
            @db_assessment.save_github_access_token(access_token)
          end
        end

        def load_signatures!
          task("Loading signatures...", true) do
            Gitrob::BlobObserver.load_signatures!
          end
        end

        def start_web_server
          return unless options[:server]
          info "Starting web application on port #{options[:port]}..."
          info "Browse to http://#{options[:bind_address]}:" \
               "#{options[:port]}/ to see results!"

          if debugging_enabled?
            Sequel::Model.db.logger = QueryLogger.new(STDOUT)
          end

          Gitrob::WebApp.run!(
            :port => options[:port].to_i,
            :bind => options[:bind_address]
          )
        end
      end
    end
  end
end
