# frozen_string_literal: true

require 'symmetric-encryption'

module KeystoreOverride
  def read
    unless ::File.exist?(file_name)
      raise(SymmetricEncryption::ConfigError,
            "Symmetric Encryption key file: '#{file_name}' not found")
    end

    unless owned?
      raise(SymmetricEncryption::ConfigError,
            "Symmetric Encryption key file '#{file_name}' has the wrong " \
            "owner (#{stat.uid}) or group (#{stat.gid}). " \
            'Expected it to be owned by current user ' \
            "#{ENV.fetch('USER', nil) || ENV.fetch('USERNAME', nil)}.")
    end

    data = read_from_file(file_name)
    key_encrypting_key ? key_encrypting_key.decrypt(data) : data
  end
end

module SymmetricEncryption
  module Keystore
    class File
      prepend KeystoreOverride
    end
  end
end
