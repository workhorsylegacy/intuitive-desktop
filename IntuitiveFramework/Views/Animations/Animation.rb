

module ID; module Views
    module Animations
        class Animation
            attr_reader :name, :parent, :actions
            attr_accessor :lifetime
            
            def initialize(parent, name, lifetime=:forever)
                @parent = parent
                @name = name
                @lifetime = lifetime
                @actions = []
                @timer = Helpers::Timer.new(0.1)
            end

            def disconnect_from_parent
                # Disconnect from the parent
                @parent.animations.delete(self) if @parent
                @parent = nil
            end

            def connect_to_parent(parent)
                self.disconnect_from_parent
                
                @parent = parent
                @parent.animations << self
            end

            def start_animation(window)
                # Load the actions into the timer
                @timer.clear_events
                actions.each do |action|
                    case action.interval
                        when :every_system_second: @timer.events_for_system_second << action.method(:fire)
                        when :every_system_minute: @timer.events_for_system_minute << action.method(:fire)
                        when :every_system_hour: @timer.events_for_system_hour << action.method(:fire)
                    end
                end
                
                # Have the timer trigger a draw after it has updated the seconds
                @timer.events_for_system_second << window.method(:schedule_draw)
       
                # FIXME: Just fire events as if the Animation lifetime was :forever for now
                # Create a thread that turns off the timer for other lifetimes
                @timer.start
            end

            def self.from_string(parent, xml)
                xml_document = REXML::Document.new(xml)
                new_animation = nil
                
                xml_document.elements.each do |element|
                    case(element.name)
                        when "Animation": new_animation = Animation::from_xml(parent, element)
                        else raise "An Animation element was not found in the xml file."
                    end
                end
            
                new_animation
            end    
          
          def self.from_xml(parent_container, element)
            new_animation = Animation.new(parent_container, element.attributes['name'])

            new_animation.lifetime = element.attributes['lifetime'] || :forever

                # Add child elements
                element.elements.each do |e|
                    case e.name
                        when "Action": Animations::Action.from_xml(new_animation, e)
                        else raise "The Animation does not know how to create a child of type '#{e.name}' from XML."
                    end
                end                    
        
                new_animation.connect_to_parent(parent_container)
            new_animation
          end         
        end
    end
end; end
