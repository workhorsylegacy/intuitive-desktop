
# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

require "#{path}/Namespace"

require 'pathname'

module ID; module Helpers
    class FileSystem
        def self.get_new_randomly_named_sub_directory(parent_directory, prefix)
          loop do
            random_name = rand(2**64).to_s
            
            # Remove the "/" from the string
            parent_directory = parent_directory.slice(0..-2) if parent_directory.slice(-1..-1) == "/"
            
            unless File.directory? "#{parent_directory}/#{prefix}#{random_name}/"
                return "#{parent_directory}/#{prefix}#{random_name}/"
            end
          end
        end 
    end
end; end
