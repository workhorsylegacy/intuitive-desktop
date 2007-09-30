

module Views
    module Animations
        class Rotate
            attr_reader :parent, :layers
            attr_accessor :interval_size, :interval_start, :degree_offset
            
            def initialize(parent)
                @parent = parent
                @interval_size = 0.0
                @interval_start = 0.0
                @degree_offset = 0.0
            end

            def disconnect_from_parent
                # Disconnect from the parent
                @parent.children.delete(self) if @parent
                @parent = nil
            end

            def connect_to_parent(parent)
                self.disconnect_from_parent
                
                @parent = parent
                @parent.children << self
            end

            def fire
                @layers.each do |layer|
                    layer.rotate += @interval_size
                end
            end

            def degree_start
                @interval_start * @interval_size + @degree_offset
            end

            def self.from_string(parent, xml)
                xml_document = REXML::Document.new(xml)
                new_rotate = nil
                
                xml_document.elements.each do |element|
                    case(element.name)
                        when "Rotate": new_rotate = Rotate::from_xml(parent, element)
                        else raise "A Rotate element was not found in the xml file."
                    end
                end
            
                new_rotate
            end    
          
          def self.from_xml(parent_container, element)
            new_rotate = Rotate.new(parent_container)

            new_rotate.interval_size = 
                  Helpers::MacroFilter.process_times(element.attributes['interval_size'], 10.0).to_f
            new_rotate.interval_start = 
                  Helpers::MacroFilter.process_times(element.attributes['interval_start'], 0.0).to_f
            
            new_rotate.degree_offset = 
                  Helpers::MacroFilter.process_times(element.attributes['degree_offset'], 0.0).to_f
            
            if element.attributes.has_key?('layers')
                layers = element.attributes['layers']
                layers = layers.split(',').collect {|layer| layer.strip}
                new_rotate.instance_variable_set("@layers", layers)
            end

                # Add child elements
                element.elements.each do |e|
                    raise "The Rotate does not know how to create a child of type '#{e.name}' from XML."
                end                    
        
                new_rotate.connect_to_parent(parent_container)
            new_rotate
          end         
        end
    end
end
