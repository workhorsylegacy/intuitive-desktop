
# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

require "#{path}/Namespace"

require 'pathname'

module ID; module Helpers
    class Logger
        # The output argument can be:
        # * a file name for outputting to a file
        # * a block for passing the message to a block
        # * a global standard output such as $stdout
        # * or anything that accepts a print method
        def initialize(output)
            if output.is_a? Proc
                # Make sure the proc has the correct number of arguments
                message = "The proc has #{output.arity} arguments, but is required to have 3 arguments."
                raise message unless output.arity == 3
                @out = output
            elsif output.is_a? String
                # Make sure the path exists
                begin
                    Pathname.new(File.dirname(output))
                rescue
                    raise "The logger cannot use the string '#{outfile}', because it is not a file path."
                end
                
                # Expand the path
                output = File.dirname(File.expand_path(output)) + '/' + File.split(output).last
                
                # Make the file if it does not exist
                File.open(output, "w").close unless File.exist?(output)
                
                @out = File.new(output, "w")
            else
                @out = output
            end
        end
        
        # Should use the status of :debug, :info, :error, :fatal for compatability with log files
        def log(status, message, exception=nil)
            if @out.is_a? Proc
                @out.call(status, message, exception)
            else
                @out.puts(status.to_s + ', ' + message)
                @out.flush
            end
        end
        
        def close
            if @out.respond_to?('closed?') && @out.respond_to?('close')
                @out.close if @out.closed?
            end
        end
    end
end; end