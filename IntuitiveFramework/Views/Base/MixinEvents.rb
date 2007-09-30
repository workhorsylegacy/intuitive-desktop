
module Views; module Base
    module MixinEvents
        attr_reader :event_map
        
        # FIXME: Should be private
        # Call in the self.from_xml methods to parse events
        def from_xml_events(element)
            element.elements.each do |e|
                case e.name
                    when "Event":
                        event = Helpers::Event.from_xml(self, e)
                        add_event event
                    else raise "The #{self.class.name} does not know how to create a child of type '#{e.name}' from XML."
                end
            end
        end
        
        # FIXME: Should be private
        # Adds an event to the event map hash
        def add_event(event)
            @event_map = {} unless @event_map
            
            name = event.name.to_sym
            @event_map[name] = [] unless @event_map.has_key? name
            @event_map[name] << event
        end
        
        def bind_to_events(models, state, view, controller)
            # Bind all the children
            if self.respond_to? :children
                @children.each do |child|
                    child.bind_to_events(models, state, view, controller)
                end
            end
            
            return unless @event_map
            
            # Connect each one to the controller's method
            @event_map.each do |name, events|
                events.each do |event|
                    # Make sure the controller implements that method
                    raise "The controller has no method named '#{event.method}' to bind to." unless controller.respond_to?(event.method)
                    #event.method = controller.method(event.method)
                    event.method_controller = controller
                    
                    # Hook the event arguments sources to the actual argument
                    if event.argument
                        name, property = event.argument.split('.')
                        control = View::control_from_element_name(view, name)
                        raise "The View has no element named '#{name}' to use as an event argument." if control == nil
                        
                        # Make sure the method requires no args
                        if control.method(property).arity > 0
                            raise "The element #{name}'s method '#{property}' cannot be used for an event argument because it requires #{control.method(property).arity} arguments."
                        end
                        
                        event.argument = control.method(property)
                    end
                    
                    # Hook the event results to the real results
                    if event.result
                        unless models.has_key?(event.result) || state.has_key?(event.result)
                            raise "Cannot send the results of the event to the Model '#{event.result}' because there is no Model by that name."
                        else
                            event.result = models[event.result] || state[event.result]
                        end
                    end
                end
            end
        end
        
        private
        
        # Fires all the events with that name, returns if no event has that name
        def fire_events(name)
            @event_map = {} unless @event_map
            
            return unless @event_map.has_key? name
                
            @event_map[name].each do |event|
                event.fire
            end
        end
    end
end; end
