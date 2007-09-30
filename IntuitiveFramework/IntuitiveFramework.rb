
# Get a list of all the libraries we will need to load
libs = {'gtk2' => ["'gtk2'",  "ruby-gnome2 or libcairo-ruby packages"],
        'cairo' => ["'cairo'", "ruby-gnome2 or libcairo-ruby packages"],
        'rsvg2' => ["'rsvg2'", "ruby-gnome2 and librsvg2-ruby packages"],
        'rexml/document' => ["'rexml'", "librexml-ruby package"],
        'monitor' => ["'monitor'", "libruby or ruby1.8-dev packages"],
        '/usr/share/rails/activerecord/lib/active_record.rb' => ["'active record'", "rails package"], 
        'openssl' => ["'openssl'", "libopenssl-ruby package"],
        'base64' => ["'base64'", "libruby or ruby1.8-dev packages"],
        'sqlite3' => ["'sqlite3'", "libsqlite3-ruby package"]}

# Load all the libraries and give the user a coherent error if any are not installed.
libs.each do |lib, description|
    begin
        require lib
    rescue LoadError
        puts "Failed to load the library #{description.first} which is usually part of the #{description.last}."
        exit
    end
end

# FIXME: We need a way to make sure sqlite works too!

# Add any boilerplate class modifications
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

# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

# Create a global strings for the main namespace file
path = File.dirname(File.expand_path(__FILE__))
$IntuitiveFramework = path

# Create a constant for the user database connection
unless defined? Models::USER_DATABASE_CONNECTION
    module Models
        USER_DATABASE_CONNECTION = { :adapter => 'sqlite3',
    						    :database => $IntuitiveFramework + "/database/database.sqlite" }
    end
end

$DataSystem = "#{path}/data_system/"

# Create a global strings for each namespace file
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

# Load all the Classes in this Namespace
[$IntuitiveFramework_Helpers,
$IntuitiveFramework_Models,
$IntuitiveFramework_Controllers,
$IntuitiveFramework_Views].each { |namespace| require namespace }

# Load the root classes
['Program', 
'Window'].each { |file_name| require "#{path}/#{file_name}" }

# Create a random seed to give us better random numbers
Kernel.srand