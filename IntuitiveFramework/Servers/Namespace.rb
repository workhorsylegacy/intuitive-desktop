

# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

# Load all the Classes in this Namespace
['CommunicationServer',
'DocumentServer',
'IdentityServer',
'ProjectServer'].each { |file_name| require "#{path}/#{file_name}" }
