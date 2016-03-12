module Gitrob
  class CLI
    module Commands
      class AcceptTermsOfUse < Gitrob::CLI::Command
        AGREEMENT_FILE_PATH = File.expand_path(
          "../../../../../agreement.txt", __FILE__)

        LICENSE_FILE_PATH = File.expand_path(
          "../../../../../LICENSE.txt", __FILE__)

        AGREEMENT = "Gitrob is designed for security professionals. " \
                    "If you use any information\nfound through this " \
                    "tool for malicious purposes that are not " \
                    "authorized by\nthe target, you are " \
                    "violating the terms of use and license of " \
                    "this\ntool. By typing y/yes, you agree to the " \
                    "terms of use and that you will use\nthis tool " \
                    "for lawful purposes only."

        VALID_ANSWERS = %w(y yes n no)
        POSITIVE_ANSWERS = %w(y yes)

        def initialize(options)
          @options = options
          return if terms_of_use_accepted?
          present_terms_of_use
          handle_user_input
        end

        private

        def terms_of_use_accepted?
          File.exist?(AGREEMENT_FILE_PATH)
        end

        def present_terms_of_use
          output "\n#{license}\n\n"
          output AGREEMENT.light_red
        end

        def handle_user_input
          if agree("\n\nDo you agree to the terms of use? (y/n): ".light_green)
            accept_terms_of_use
          else
            fatal("Exiting Gitrob.")
          end
        end

        def accept_terms_of_use
          File.open(AGREEMENT_FILE_PATH, "w") do |file|
            file.write("user accepted")
          end
        end

        def license
          File.read(LICENSE_FILE_PATH)
        end
      end
    end
  end
end
