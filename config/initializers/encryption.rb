require 'symmetric-encryption'

config_file = nil
if defined?(JRUBY_VERSION)
  config_file = java.lang.System.getProperty('kaui.encryption.filename')
end
config_file ||= (ENV['KAUI_ENCRYPTION_FILENAME'] || 'config/symmetric-encryption.yml')

SymmetricEncryption.load!('config/symmetric-encryption.yml')
