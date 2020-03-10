require 'symmetric-encryption'

if defined?(JRUBY_VERSION)
  SymmetricEncryption.load!(java.lang.System.getProperty('kaui.encryption.filename', 'config/symmetric-encryption.yml'))
else
  SymmetricEncryption.load!('config/symmetric-encryption.yml')
end
