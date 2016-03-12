module Gitrob
  class CLI
    module Commands
      class Server < Gitrob::CLI::Command
        def initialize(options)
          @options = options
          info "Starting web application on port #{options[:port]}..."

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
