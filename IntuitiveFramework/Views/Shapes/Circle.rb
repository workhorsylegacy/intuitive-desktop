
module Views
    module Shapes
        class Circle
        	attr_reader :name, :model_radius
        	attr_accessor :background
        
        	def initialize(name, model_radius)
        		@name = name
        		@model_radius = model_radius
        	end
        
        	def draw(window)
        	   @background.draw(window) if @background
        	end
        
        	def self.from_xml(element)
        		new_circle = Circle.new(
        							element.attributes['name'],
        							element.attributes['model_radius'])
        
        		element.elements.each { |e|
        			case(e.name)
        				when "Background": new_circle.background = Views::Styles::Background.from_xml(e)
        			end
        		}
        
        		new_circle
        	end
        end
    end
end