

module ID; module Views; module Data
        class Polygon < Views::Base::ContainerChild
            attr_reader :name
            
            def initialize(name)
                super()
                @name = name
            end
    
          def draw(cairo_context, window)
          end   
          
          def self.from_xml(parent_container, element)
                new_polygon = Polygon.new(element.attributes['name'])

                # Add child elements
                element.elements.each do |e|
                    case e.name
                        when "Event": new_polygon.add_event(Helpers::Event.from_xml(new_polygon, e))
                        when "Binding": Helpers::Binding.from_xml(new_polygon, e)
                        else raise "The Polygon does not know how to create a child of type '#{e.name}' from XML."
                    end
                end                                
        
                new_polygon.connect_to_container(parent_container)
            
                new_polygon
          end         
        end
end; end; end
