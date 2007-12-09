
# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

require "#{path}/Namespace"

require 'pathname'

module ID; module Helpers
    class Event
        attr_reader :name
        attr_accessor :method, :method_controller, :result, :argument
        
        def initialize(parent, name, method, argument=nil, result=nil)
            @parent, @name, @method, @argument, @result = parent, name, method, argument, result
        end
        
        def fire
            # Just return if there is no method
            return unless @method
            
            # Remove all the old results from the table
            @result.delete_all if @result     
            
            # Call the event and put the result into the event_result
            if @argument
                source_models = @method_controller.send(@method, @argument.call)
            else
                source_models = @method_controller.send(@method)
            end
            return if @result == nil || source_models.length == 0
            
            # Save the result into the event_result Model
            source_models.each do |source_model|
                dest_model = @result.new
                (source_model.attribute_names - ['id']).each do |attribute_name|
                    unless dest_model.respond_to? attribute_name
                        raise "The Model '#{dest_model.name}' is not compatable with the Model '#{source_models.class.name}'. Missing the attribute '#{attribute_name}'."
                    end
                    dest_model.send("#{attribute_name}=", source_model.send(attribute_name))
                end
                dest_model.save!
            end
        end
        
		def self.from_xml(parent, element)
			new_event = Event.new(parent,
			                        element.attributes['name'],
									element.attributes['method'],
									element.attributes['argument'],
									element.attributes['result'])

            # Make sure the parent has this event to call
            message = "The parent of this Event is a #{parent.class.name}, and does not have a method called '#{new_event.name}'."
            raise message unless parent.respond_to? new_event.name

            # Make sure there are no child elements
	        element.elements.each do |e|
	            raise "An Event element cannot have any child elements."
	        end

			new_event
		end    
    end
end; end
