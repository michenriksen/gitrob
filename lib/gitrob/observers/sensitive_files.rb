module Gitrob
  module Observers
    class SensitiveFiles

      class InvalidPatternFileError < StandardError; end
      class InvalidPatternError < StandardError; end

      VALID_KEYS  = %w(part type pattern caption description)
      VALID_PARTS = %w(path filename extension)
      VALID_TYPES = %w(match regex)

      def self.observe(blob)
        return if !blob.size || blob.size.zero?
        patterns.each do |pattern|
          check_blob(blob, pattern)
        end
      end

      def self.load_patterns!
        patterns = read_pattern_file!
        validate_patterns!(patterns)
        @patterns = patterns
      end

      def self.patterns
        @patterns
      end

    private

      def self.read_pattern_file!
        JSON.parse(File.read("#{File.dirname(__FILE__)}/../../../patterns.json"))
      rescue JSON::ParserError => e
        raise InvalidPatternFileError.new("Cannot parse pattern file: #{e.message}")
      end

      def self.validate_patterns!(patterns)
        if !patterns.is_a?(Array) || patterns.empty?
          raise InvalidPatternFileError.new("Pattern file contains no patterns")
        end
        patterns.each do |pattern|
          validate_pattern!(pattern)
        end
      end

      def self.validate_pattern!(pattern)
        pattern.keys.each do |key|
          if !VALID_KEYS.include?(key)
            raise InvalidPatternError.new("Pattern contains unknown key: #{key}")
          end
        end

        if !VALID_PARTS.include?(pattern['part'])
          raise InvalidPatternError.new("Pattern has unknown part: #{pattern['part']}")
        end

        if !VALID_TYPES.include?(pattern['type'])
          raise InvalidPatternError.new("Pattern has unknown type: #{pattern['type']}")
        end
      end

      def self.check_blob(blob, pattern)
        haystack = blob.send(pattern['part'].to_sym) #Problem
        if pattern['type'] == 'match'
          if haystack == pattern['pattern']
            blob.findings.new(
              :caption     => pattern['caption'],
              :description => pattern['description']
            )
          end
        else
          regex = Regexp.new(pattern['pattern'], Regexp::IGNORECASE)
          if !regex.match(haystack).nil?
            blob.findings.new(
              :caption     => pattern['caption'],
              :description => pattern['description']
            )
          end
        end
      end
    end
  end
end
