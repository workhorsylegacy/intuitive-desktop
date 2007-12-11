
# Make sure ruby gems is installed
begin
	require 'rubygems'
rescue LoadError
	puts "Failed to load the library 'ruby gems' which is usually part of the 'rubygems' package."
	exit
end

# Get a list of all the libraries we will need to load
libs = {'gtk2' => ["'gtk2'",  :require, "ruby-gnome2 or libcairo-ruby packages"],
        'cairo' => ["'cairo'", :require, "ruby-gnome2 or libcairo-ruby packages"],
        'rsvg2' => ["'rsvg2'", :require, "ruby-gnome2 and librsvg2-ruby packages"],
        'rexml/document' => ["'rexml'", :require, "librexml-ruby package"],
        'monitor' => ["'monitor'", :require, "libruby or ruby1.8-dev packages"],
		'active_record' => ["'active record'", :both, "rails, or activerecord packages or gems"], 
        'openssl' => ["'openssl'", :require, "libopenssl-ruby package"],
        'base64' => ["'base64'", :require, "libruby or ruby1.8-dev packages"],
        'sqlite3' => ["'sqlite3'", :require, "libsqlite3-ruby package"],
        'soap/wsdlDriver' => ["'WSDL Driver'", :require, "standard Ruby install"]}

# Load all the libraries and create a list of coherent errors if any are not installed.
error_messages = []
libs.each do |lib, description|
    begin
		case description[1]
        	when :require: require lib
			when :gem: gem lib
			when :both:
				begin
					gem lib
				rescue Gem::LoadError
					require lib
				end
		end
    rescue LoadError
        error_messages << "Failed to load the library #{description.first} which is usually part of the #{description.last}."
    end
end

# Show any errors
error_messages.each do |message|
	puts message
end
exit if error_messages.length > 0

# Add any boilerplate class modifications

# This lets us cast strings into bools
class String
	def to_b
		case(self.downcase)
			when "true": true
			when "false": false
			else
				false
		end
	end
end

class TrueClass
    def to_b
        self
    end
end

class FalseClass
    def to_b
        self
    end
end

# This lets us compare symbols
class Symbol
    def <=>(other)
        self.to_s <=> other.to_s
    end
end


# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

# Create a global string for the main namespace file
path = File.dirname(File.expand_path(__FILE__))
$IntuitiveFramework = path

# Create a constant for the user database connection
unless defined? ID::Models::USER_DATABASE_CONNECTION
    module ID; module Models
        USER_DATABASE_CONNECTION = { :adapter => 'sqlite3',
    						    :database => $IntuitiveFramework + "/database/database.sqlite" }
    end; end
end

$DataSystem = "#{path}/data_system/"
$TempCommunicationDirectory = "#{path}/temp_communication/"
$TempTables = "#{path}/temporary_tables/"

# Create a global string for each namespace file
$IntuitiveFramework_Helpers = "#{path}/Helpers/Namespace"

$IntuitiveFramework_Models = "#{path}/Models/Namespace"
$IntuitiveFramework_Models_System = "#{path}/Models/System/Namespace"
$IntuitiveFramework_Models_Data = "#{path}/Models/Data/Namespace"

$IntuitiveFramework_Controllers = "#{path}/Controllers/Namespace"

$IntuitiveFramework_Servers = "#{path}/Servers/Namespace"

$IntuitiveFramework_Views = "#{path}/Views/Namespace"
$IntuitiveFramework_Veiws_Styles = "#{path}/Views/Styles/Namespace"
$IntuitiveFramework_Views_Shapes = "#{path}/Views/Shapes/Namespace"
$IntuitiveFramework_Views_Data = "#{path}/Views/Data/Namespace"
$IntuitiveFramework_Views_Base = "#{path}/Views/Base/Namespace"
$IntuitiveFramework_Views_Animations = "#{path}/Views/Animations/Namespace"

# Load all the Classes into this Namespace
[$IntuitiveFramework_Helpers,
$IntuitiveFramework_Models,
$IntuitiveFramework_Controllers,
$IntuitiveFramework_Views].each { |namespace| require namespace }

# Load the root classes
['Program'].each { |file_name| require "#{path}/#{file_name}" }

# Create a random seed to give us better random numbers
Kernel.srand
