if defined?(JRUBY_VERSION)
KillBillClient.url = java.lang.System.getProperty('kaui.url', 'http://127.0.0.1:8080')
KillBillClient.api_key = java.lang.System.getProperty('kaui.api_key', 'bob')
KillBillClient.api_secret = java.lang.System.getProperty('kaui.api_secret', 'lazar')
else
KillBillClient.url = 'http://127.0.0.1:8080'
end


