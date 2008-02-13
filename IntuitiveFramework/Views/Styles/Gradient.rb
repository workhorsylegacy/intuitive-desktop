
module ID; module Views; module Styles
        class Gradient
        	attr_accessor :light_color, :dark_color
        
        	def initialize(light_color, dark_color)
        		@light_color = light_color
        		@dark_color = dark_color
        	end
        
        	def draw(window)
        	end
        
        	def self.from_xml(element)
        		new_gradient = Gradient.new(nil, nil)
        
        		new_gradient.light_color = element.attributes['light_color']
        		new_gradient.dark_color = element.attributes['dark_color']
        
        		new_gradient
        	end
        end
end; end; end