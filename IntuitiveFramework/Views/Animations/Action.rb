

module Views
    module Animations
        class Action
            attr_reader :name, :parent, :interval, :children
            
            def initialize(parent, name, interval=:once)
                @parent = parent
                @name = name
                @interval = interval
                @children = []
            end

            def interval=(value)
                known_values = [:once, :none,
                               :every_second, :every_minute, :every_hour,
                               :every_system_second, :every_system_minute, :every_system_hour]
                                  
                # Set the interval as a known value
                @interval = value.to_sym and return if known_values.include?(value.to_sym)
                
                # Set the interval as a number in seconds
                # FIXME: Is there a is_numeric?(String) in Ruby?
                # FIXME: Raise if the value is not a number
                @interval = value.to_f
            end

            def disconnect_from_parent
                # Disconnect from the parent
                @parent.actions.delete(self) if @parent
                @parent = nil
            end

            def connect_to_parent(parent)
                self.disconnect_from_parent
                
                @parent = parent
                @parent.actions << self
            end

            def fire
                @children.each do |child|
                    child.fire
                end
            end

            def self.from_string(parent, xml)
                xml_document = REXML::Document.new(xml)
                new_action = nil
                
                xml_document.elements.each do |element|
                    case(element.name)
                        when "Action": new_action = Action::from_xml(parent, element)
                        else raise "An Action element was not found in the xml file."
                    end
                end
            
                new_action
            end    
          
          def self.from_xml(parent_container, element)
            new_action = Action.new(parent_container, element.attributes['name'])

            new_action.interval = element.attributes['interval'] || :once

                # Add child elements
                element.elements.each do |e|
                    case e.name
                        when "Rotate": Animations::Rotate.from_xml(new_action, e)
                        else raise "The Action does not know how to create a child of type '#{e.name}' from XML."
                    end
                end                    
        
                new_action.connect_to_parent(parent_container)
            new_action
          end         
        end
    end
end
