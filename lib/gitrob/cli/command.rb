module Gitrob
  class CLI
    class Command
      attr_reader :options

      def self.start(*args)
        new(*args)
      end

      def initialize(*args) # rubocop:disable Lint/UnusedMethodArgument
      end

      def info(*args)
        Gitrob::CLI.info(*args)
      end

      def task(message, fatal_error=false, &block)
        Gitrob::CLI.task(message, fatal_error, &block)
      end

      def warn(*args)
        Gitrob::CLI.warn(*args)
      end

      def error(*args)
        Gitrob::CLI.error(*args)
      end

      def fatal(*args)
        Gitrob::CLI.fatal(*args)
      end

      def debug(*args)
        Gitrob::CLI.debug(*args)
      end

      def debugging_enabled?
        Gitrob::CLI.debugging_enabled?
      end

      def output(*args)
        Gitrob::CLI.output(*args)
      end

      def thread_pool
        pool = Thread::Pool.new(options[:threads] || 5)
        yield pool
        pool.shutdown
      end

      def progress_bar(message, options)
        progress_bar = Gitrob::CLI::ProgressBar.new(message, options)
        yield progress_bar
        progress_bar.finish
      end
    end
  end
end
