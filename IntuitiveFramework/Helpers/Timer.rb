
# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

require "#{path}/Namespace"

require 'monitor'

module ID; module Helpers
    class Timer
        attr_reader :status, :precision
        attr_reader :events_for_system_second, :events_for_system_minute, :events_for_system_hour
        
        # FIXME: We should enforce that the .arity of events is zero so they won't crash when called
        def initialize(precision)
            @precision = precision
        
            @events_for_system_second = [].extend(MonitorMixin)
            @events_for_system_minute = [].extend(MonitorMixin)
            @events_for_system_hour = [].extend(MonitorMixin)
            @status = :stopped
            @time = nil
            @last_sec = nil
            @last_min = nil
            @last_hour = nil
            
            @tick_thread = nil
        end
        
        def start
            # Just return if we are already started
            return if @status == :started
            
            # Set the status to started
            @status = :started
            
            # Set the current time as the last tick
            @time = Time.now
            @last_sec = @time.sec
            @last_min = @time.min
            @last_hour = @time.hour
            
            # Start the tick thread that ticks until the status changes
            @tick_thread = Thread.new do
                while @status == :started
                    sleep(@precision)
                    next unless @status == :started
                    perform_tick
                end
            end
        end
        
        def stop
            # Just return if we are already stopped
            return if @status == :stopped
            
            # Set the status to stopped
            @status = :stopped
        end
        
        def clear_events
            [@events_for_system_second,
            @events_for_system_minute,
            @events_for_system_hour].each do |event_set|
                event_set.clear
            end
        end
        
        private
        
        def perform_tick
            @time = Time.now
            
            # Fire the events for system second
            if @time.sec != @last_sec
                @last_sec = @time.sec
                @events_for_system_second.synchronize do
                    @events_for_system_second.each do |event|
                        event.call
                    end
                end
            end
            
            # Fire the events for system minute
            if @time.min != @last_min
                @last_min = @time.min
                @events_for_system_minute.synchronize do
                    @events_for_system_minute.each do |event|
                        event.call
                    end
                end
            end      
            
            # Fire the events for system hour
            if @time.hour != @last_hour
                @last_hour = @time.hour
                @events_for_system_hour.synchronize do
                    @events_for_system_hour.each do |event|
                        event.call
                    end
                end
            end             
        end
    end
end; end
