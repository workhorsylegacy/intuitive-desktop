
module ID; module Views; module Data
        # FIXME: Should work like a GTK expander and an HTML bulleted/numbered list
        class List < Views::Base::ContainerParentAndChild
            attr_accessor :name, :on_populate_event, :on_selection_changed_event, :select_mode, :point_style
        
            def initialize(name)
                super('vertical')
                @name = name
            end
        
            def draw(window)        
#                #raise (self.methods.sort - Object.new.methods).inspect
#                if self.uses_data_binding?
#                    @children.each do |child|
#                        child.disconnect_from_container
#                    end
#                
#                    models = @model.find_by_sql(@binding)
#                    models.each do |model|
#                        text = Text.new('temp', nil, nil, nil)
#                        text.text = model.name
#                        text.connect_to_container(self)
#                    end
#                end
#                
#                @children.each do |child|
#                    child.draw(window)
#                end
            end
            
            def on_key_press_trigger(key_board_group, modify_keys, key_value)
                # If user pressed tab, move to the next control
                case key_value
                    when :tab: puts('Tab to next control here.')
                end
            
                fire_events :on_key_press_event
            end
            
            def on_selection_changed_trigger
                fire_events :on_selection_changed_event
            end
        
            def on_mouse_up_trigger(x, y, proc = nil)
                fire_events :on_mouse_up_event
                
                # Fire any on_selection_changed_trigger
                self.on_selection_changed_trigger
            end
        
            def on_populate_trigger
                fire_events :on_populate_event
            end
        
            def on_selection_changed_trigger
                fire_events :on_selection_changed_event
            end
        
        	def self.from_xml(parent_container, element)
        		new_list = List.new(element.attributes['name'])

                new_list.select_mode = element.attributes['select_mode'] || :single
        		new_list.point_style = element.attributes['point_style'] || :numbers
        
                # Add child elements
                element.elements.each do |e|
                    case e.name
                        when "Event": new_list.add_event(Helpers::Event.from_xml(new_list, e))
                        when "Binding": Helpers::Binding.from_xml(new_list, e)
                        when "Button": Views::Data::Button.from_xml(new_list, e)
                        when "Drawing": Views::Data::Drawing.from_xml(new_list, e)
                        when "Text": Views::Data::Text.from_xml(new_list, e)
                        when "List": Views::Data::List.from_xml(e)
                        when "Circle": Views::Shapes::Circle.from_xml(e)
                        when "Spinner": Views::Data::Spinner.from_xml(new_list, e)
                        when "Container": Views::Container.from_xml(new_list, e)
                        else raise "The List does not know how to create a child of type '#{e.name}' from XML."
                    end
                end
        
                new_list.connect_to_container(parent_container)
        
        		new_list
        	end       	
        end
end; end; end
