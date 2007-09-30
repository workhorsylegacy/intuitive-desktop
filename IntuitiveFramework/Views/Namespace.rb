
require 'gtk2'
require 'cairo'
require 'rexml/document'

# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

# Load the base classes and modules
require "#{path}/Base/Namespace"
require "#{path}/Data/Namespace"
require "#{path}/Shapes/Namespace"
require "#{path}/Styles/Namespace"

# Load all the Classes in this Namespace
['Container',
'View'].each { |file_name| require "#{path}/#{file_name}" }


