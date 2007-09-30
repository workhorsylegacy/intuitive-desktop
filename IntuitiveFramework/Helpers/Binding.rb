
# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

require "#{path}/Namespace"

module Helpers
    class Binding
        attr_reader :name, :parent
        attr_accessor :model, :on_model_change, :on_view_change, :model_properties, :view_properties
        
        def initialize(parent, name, model, model_properties, view_properties, on_model_change=nil, on_view_change=nil)
            @parent = parent
            @name = name
            @model = model
            
            @model_properties = 
            if model_properties.is_a? String
               model_properties.split(',').collect { |n| n.strip.to_sym }
            elsif model_properties.is_a? Array
                model_properties.collect { |n| n.to_sym }
            else
                raise "Can't figure out how to convert the '#{model_properties.class.name}' to the model_properties."
            end
            
            @view_properties = 
            if view_properties.is_a? String
               view_properties.split(',').collect { |n| n.strip.to_sym }
            elsif view_properties.is_a? Array
                view_properties.collect { |n| n.to_sym }
            else
                raise "Can't figure out how to convert the '#{view_properties.class.name}' to the view_properties."
            end
            
            @on_model_change = (on_model_change || :do_nothing).to_sym
            @on_view_change = (on_view_change || :do_nothing).to_sym
            
            # Make sure there is a perent
            raise "The binding needs a parent object to connect to." unless @parent
            
            # Make sure the view properties are correct
            @view_properties.each do |property|
                message = "A View of type '#{@parent.class.name}' does not have a property named '#{property}' to bind to."
                raise message unless @parent.respond_to?(property) && @parent.respond_to?("#{property}=")
            end
        end
        
        def on_model_change=(value)
            # Make sure the mode is valid
            unless [:save_changes_to_view, :do_nothing].include? value.to_sym
                raise "The Binding's on_model_change of #{value.to_s} is not supported"
            end
            
            # Save the new mode
            @on_model_change = value.to_sym
            
            # Save the changes in the model
            self.save_model_changes
        end
        
        def on_view_change=(value)
            # Make sure the mode is valid
            unless [:save_changes_to_model, :do_nothing].include? value.to_sym
                raise "The Binding's on_view_change of #{value.to_s} is not supported"
            end
            
            # Save the new mode
            @on_view_change = value.to_sym
            
            # Save the changes in the model
            self.save_model_changes
        end        
        
        def model=(value)
            @model = value
            
            # Save the changes in the model
            self.save_model_changes            
        end
        
        def get_model_data
            datas = @model.find_by_sql("select #{@model_properties.join(',')} from #{@model.name.tableize}")
            
            # Return the data converted into an array
            datas.collect do |data|
                @model_properties.collect do |property|
                    data.send(property)
                end
            end
        end
        
        def set_model_data(name, value)
            @model.find(:all).each do |model|
                index = @view_properties.index(name)
                model_property = @model_properties[index]
                model.send("#{model_property}=", value)
                model.update
            end
        end
        
        def self.from_string(parent, xml)
            xml_document = REXML::Document.new(xml)
            new_binding = nil
            
            xml_document.elements.each do |element|
                case element.name
                    when "Binding": new_binding = Binding::from_xml(parent, element)
                    else raise "A Binding element was expected, but not found."
                end
            end
        
            new_binding
        end
        
        def self.from_xml(parent, element)
            new_binding = Binding.new(parent,
			                        element.attributes['name'],
                              element.attributes['model'],
                              element.attributes['model_properties'],
                              element.attributes['view_properties'],
                              element.attributes['on_model_change'],
                              element.attributes['on_view_change'])

            # Make sure there are no child elements
            element.elements.each do |e|
                raise "An Binding element cannot have any child elements."
            end

            parent.add_binding(new_binding)

            new_binding
        end
        
        def save_model_changes
            # Just return if there is no mode and model, and the model us not an ActiveRecord
            return unless @mode && @model && @model.is_a?(ActiveRecord::Base)
            
            
        end
    end
end
