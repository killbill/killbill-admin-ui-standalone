# frozen_string_literal: true

require 'symmetric-encryption'

config_file = nil
config_file = java.lang.System.getProperty('kaui.encryption.filename') if defined?(JRUBY_VERSION)
config_file ||= (ENV['KAUI_ENCRYPTION_FILENAME'] || 'config/symmetric-encryption.yml')

SymmetricEncryption.load!(config_file)
