
module ID; module Views; module Styles
        class Background
        	attr_accessor :elements
        
        	def initialize
        		@elements = []
        	end
        
        	def draw(window)
        	   @elements.each { |element|
        	       element.draw(window)
        	   }
        	end
        
        	def self.from_xml(element)
        		new_background = Background.new
        
        		element.elements.each { |e|
        			case(e.name)
        				when "Gradient": new_background.elements << Gradient.from_xml(e)
        			end
        		}
        
        		new_background
        	end
        end
end; end; end