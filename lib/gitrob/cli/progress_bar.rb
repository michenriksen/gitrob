module Gitrob
  class CLI
    class ProgressBar
      def initialize(message, options={})
        @options = {
          :format =>
            "#{'[*]'.light_blue} %t %c/%C %B %j% %e",
          :progress_mark => "|".light_blue,
          :remainder_mark => "|"
        }.merge(options)
        @mutex = Mutex.new
        Gitrob::CLI.info(message)
        @progress_bar = ::ProgressBar.create(@options)
      end

      def finish
        progress_bar.finish
      end

      def info(message)
        progress_bar.log("#{'[+]'.light_blue} #{message}")
      end

      def error(message)
        progress_bar.log("#{'[!]'.light_red} #{message}")
      end

      def warn(message)
        progress_bar.log("#{'[!]'.light_yellow} #{message}")
      end

      def method_missing(method, *args, &block)
        if progress_bar.respond_to?(method)
          progress_bar.send(method, *args, &block)
        else
          super
        end
      end

      private

      def progress_bar
        @mutex.synchronize { @progress_bar }
      end
    end
  end
end
