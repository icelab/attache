require "base64"
require "openssl"

module Attache
  class DownloadURLBuilder
    def initialize(host, secret_key)
      @host = host
      @secret_key = secret_key
    end

    # Example usage: url("foo/bar.jpg", [:resize, "250x200>"], [:rotate, "-90"], [:flip])
    def url(path, *instructions)
      raise ArgumentError, "at least one instruction must be provided" if instructions.length.zero?

      instruction_string = Base64.urlsafe_encode64(JSON.generate(instructions), padding: false)

      build_url(path, instruction_string)
    end

    def original_url(path)
      build_url(path, "original")
    end

    def backup_url(path)
      build_url(path, "backup")
    end

    private

    def build_url(path, instruction_string)
      directory = File.dirname(path)
      file_name = File.basename(path)
      hmac      = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), secret_key, instruction_string)

      [host, "view", directory, instruction, hmac, file_name].join("/")
    end
  end
end
