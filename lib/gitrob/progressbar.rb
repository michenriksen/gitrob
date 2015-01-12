# coding: utf-8

module Gitrob
  class ProgressBar
    TITLE_MAX_LENGTH = 25

    def initialize(message, options)
      @options = {
        :format         => " #{Paint['[*]', :bright, :blue]} %c/%C %B %j% %e",
        :progress_mark  => Paint['▓', :bright, :blue],
        :remainder_mark => '░',
      }.merge(options)
      Gitrob::status(message)
      @mutex = Mutex.new
      @progress_bar = ::ProgressBar::Base.new(@options)
    end

    def finish!
      @mutex.synchronize { @progress_bar.finish }
    end

    def log(message)
      @mutex.synchronize do
        @progress_bar.log(" #{Paint['[>]', :bright, :blue]} #{message}")
      end
    end

    def log_error(message)
      @mutex.synchronize do
        @progress_bar.log(" #{Paint['[!]', :bright, :red]} #{message}")
      end
    end

    def method_missing(method, *args, &block)
      if @progress_bar.respond_to?(method)
        @mutex.synchronize { @progress_bar.send(method, *args, &block) }
      else
        super
      end
    end

  private

    def make_title(t)
      t = t.to_s
      if t.size > TITLE_MAX_LENGTH
        t = "#{t[0, (TITLE_MAX_LENGTH-3)]}..."
      end
      " #{Paint['[>]', :bright, :blue]} #{Paint[t.rjust(TITLE_MAX_LENGTH), :bright, :blue]}"
    end
  end
end
