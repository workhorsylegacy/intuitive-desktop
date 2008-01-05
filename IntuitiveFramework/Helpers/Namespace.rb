

# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

# Load all the Classes in this Namespace
['Binding',
'Event',
'FileSystem',
'Color',
'Logger',
'EasySocket',
'MacroFilter',
'Proxy',
'SystemProxy',
'Timer'].each { |file_name| require "#{path}/#{file_name}" }
