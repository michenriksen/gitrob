module Gitrob
  module Jobs
    class Assessment
      include SuckerPunch::Job

      def perform(targets, options)
        options[:server] = false
        Gitrob::CLI::Commands::Analyze.new(targets, options)
      end
    end
  end
end
