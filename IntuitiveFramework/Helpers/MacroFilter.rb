
# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

require "#{path}/Namespace"

require 'pathname'

module ID; module Helpers
    # This filter will return a new value if the value is a known macro, 
    # otherwise it will return the default value. If the default is nil,
    # it will return the original value
    class MacroFilter
        def self.process_times(value, default = nil)
            is_plural = value.is_a?(String) && value.include?(',')
            
            if is_plural
                value.gsub(' ', '').split(',').collect do |v|
                    replace_with_time_value(v, default)
                end
            else
                replace_with_time_value(value.gsub(' ', ''), default)
            end
        end
        
        def self.process_keys(value)
            return nil if value == nil
            is_plural = value.is_a?(String) && value.include?(',')
            
            if is_plural
                value.gsub(' ', '').split(',').collect do |v|
                    replace_with_key_value(v)
                end
            else
                replace_with_key_value(value.gsub(' ', ''))
            end
        end
        
        def self.replace_with_time_value(value, default)
            case value
                when "System.time.seconds": Time.now.sec
                when "System.time.minutes": Time.now.min
                when "System.time.hours": Time.now.hour
                when "System.time.hours_24": Time.now.hour
                when "System.time.hours_12":
                    hours = Time.now.hour
                    hours -= 12 if hours > 12
                    hours
                else value || default
            end
        end
        
        def self.replace_with_key_value(value)
            # Keys
            return value.split('+').sort.collect do |v|
                v.to_sym
            end
        end
    end
end; end