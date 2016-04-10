module Gitrob
  class BlobObserver
    SIGNATURES_FILE_PATH = File.expand_path(
      "../../../signatures.json", __FILE__)
    CUSTOM_SIGNATURES_FILE_PATH = File.join(
      Dir.home, ".gitrobsignatures")

    REQUIRED_SIGNATURE_KEYS = %w(part type pattern caption description)
    ALLOWED_TYPES           = %w(regex match)
    ALLOWED_PARTS           = %w(path filename extension)

    class Signature < OpenStruct; end
    class CorruptSignaturesError < StandardError; end

    def self.observe(blob)
      signatures.each do |signature|
        if signature.type == "match"
          observe_with_match_signature(blob, signature)
        else
          observe_with_regex_signature(blob, signature)
        end
      end
      blob.flags_count = blob.flags.count
      blob.save
      blob.flags_count
    end

    def self.signatures
      load_signatures! unless @signatures
      @signatures
    end

    def self.load_signatures!
      @signatures = []
      signatures = JSON.load(File.read(SIGNATURES_FILE_PATH))
      validate_signatures!(signatures)
      signatures.each_with_index do |signature|
        @signatures << Signature.new(signature)
      end
    rescue CorruptSignaturesError => e
      raise e
    rescue
      raise CorruptSignaturesError, "Could not parse signature file"
    end

    def self.unload_signatures
      @signatures = []
    end

    def self.custom_signatures?
      File.exist?(CUSTOM_SIGNATURES_FILE_PATH)
    end

    def self.load_custom_signatures!
      signatures = JSON.load(File.read(CUSTOM_SIGNATURES_FILE_PATH))
      validate_signatures!(signatures)
      signatures.each do |signature|
        @signatures << Signature.new(signature)
      end
    rescue CorruptSignaturesError => e
      raise e
    rescue
      raise CorruptSignaturesError, "Could not parse signature file"
    end

    def self.validate_signatures!(signatures)
      if !signatures.is_a?(Array) || signatures.empty?
        fail CorruptSignaturesError,
             "Signature file contains no signatures"
      end
      signatures.each_with_index do |signature, index|
        begin
          validate_signature!(signature)
        rescue CorruptSignaturesError => e
          raise CorruptSignaturesError,
                "Validation failed for Signature ##{index + 1}: #{e.message}"
        end
      end
    end

    def self.validate_signature!(signature)
      validate_signature_keys!(signature)
      validate_signature_type!(signature)
      validate_signature_part!(signature)
    end

    def self.validate_signature_keys!(signature)
      REQUIRED_SIGNATURE_KEYS.each do |key|
        unless signature.key?(key)
          fail CorruptSignaturesError,
               "Missing required signature key: #{key}"
        end
      end
    end

    def self.validate_signature_type!(signature)
      unless ALLOWED_TYPES.include?(signature["type"])
        fail CorruptSignaturesError,
             "Invalid signature type: #{signature['type']}"
      end
    end

    def self.validate_signature_part!(signature)
      unless ALLOWED_PARTS.include?(signature["part"])
        fail CorruptSignaturesError,
             "Invalid signature part: #{signature['part']}"
      end
    end

    def self.observe_with_match_signature(blob, signature)
      haystack = blob.send(signature.part.to_sym)
      return unless haystack == signature.pattern
      blob.add_flag(
        :caption     => signature.caption,
        :description => signature.description,
        :assessment  => blob.assessment
      )
    end

    def self.observe_with_regex_signature(blob, signature)
      haystack = blob.send(signature.part.to_sym)
      regex    = Regexp.new(signature.pattern, Regexp::IGNORECASE)
      return if regex.match(haystack).nil?
      blob.add_flag(
        :caption     => signature.caption,
        :description => signature.description,
        :assessment  => blob.assessment
      )
    end
  end
end
