module Gitrob
  class CLI
    module Commands
      class Banner < Gitrob::CLI::Command
        def initialize(options)
          @options = options
          output banner if options[:banner]
          info "Starting Gitrob version #{Gitrob::VERSION} " \
          "at #{Time.now.strftime('%Y-%m-%d %H:%M %Z')}"
          debug "Debugging mode enabled"
        end

        private

        def banner
          "     _ _           _\n" \
          " ___|_| |_ ___ ___| |_\n" \
          "| . | |  _|  _| . | . |\n" \
          "|_  |_|_| |_| |___|___|\n" \
          "|___|".light_blue + " By @michenriksen\n\n".light_white
        end
      end
    end
  end
end
