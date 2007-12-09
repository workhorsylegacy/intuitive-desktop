
module ID; module Views; module Styles
        class Color
        	attr_reader :value
        
            def initialize(value)
                @value = value
            end
        
        	def self.from_name(name)
        		value = 
        		case(name.downcase)
        			when "red":      0xFF0000
        			when "green":    0x00FF00
        			when "blue":     0x0000FF
        			else
        				throw "Color::from_name does not know the color '#{name}'"
        		end
        
        		Color.new(value)
        	end
        end
end; end; end