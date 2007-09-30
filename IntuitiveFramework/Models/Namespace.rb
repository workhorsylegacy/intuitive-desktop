
# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

# Load external dependencies
require '/usr/share/rails/activerecord/lib/active_record.rb'

# Load all the Classes in this Namespace
['Branch',
'Category', 
'Document',
'EncryptionKey', 
'Group',
'Project',
'User'].each { |file_name| require "#{path}/#{file_name}" }

require $IntuitiveFramework_Models_System
require $IntuitiveFramework_Models_Data
