
# get the path of this file
path = File.dirname(File.expand_path(__FILE__))


# Load all the Classes in this Namespace
['Button',
'Drawing',
'Labels',
'Line',
'List',
'Polygon',
'Spinner',
'Text'].each { |file_name| require "#{path}/#{file_name}" }

