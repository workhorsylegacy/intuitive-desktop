
require $IntuitiveFramework_Helpers

module ID; module Helpers
	class TestLogger < Test::Unit::TestCase
        def setup
            @logger = nil
            @dir_name = File.expand_path('~/.unit_tests_temp') + '/'
            @file_name = @dir_name + 'unit_test.txt'
            Dir.mkdir(@dir_name)
        end
        
        def teardown
            @logger.close if @logger
            (Dir.entries(@dir_name) - ['..', '.']).each {|file|  File.delete(@dir_name + file) }
            Dir.rmdir(@dir_name)
        end
        
        def test_log_to_file
            # Add some messages to the log file
            @logger = Helpers::Logger.new(@file_name)
            @logger.log :info, "did it work?"
            @logger.log :info, "are you sure?"
            @logger.close
            
            # Make sure the file was written correctly
            file = File.open(@file_name, "r")
            file_contents = file.read
            file.close
            assert_equal("info, did it work?\ninfo, are you sure?\n", file_contents)
        end

        def test_log_to_output
            # Add some messages to the log
            @logger = Helpers::Logger.new($stdout)
            @logger.log :info, "did it work?"
            @logger.log :info, "are you sure?"
            @logger.close
            
            # Make sure the output was written correctly
            # FIXME: How do I read from the standard output to see if this is correct?
            warn "Helpers::TestLogger.test_log_to_output: How do I read from the standard output to see if this is correct?"
            #assert_equal("info, did it work?\ninfo, are you sure?\n", $stdout)
        end
        
        def test_log_to_proc
            # Create a switch to flip when the logger is called
            was_logged_used = false
        
            # Add some messages to the log file
            @logger = Helpers::Logger.new(Proc.new { |status, message, exception| was_logged_used = true })
            @logger.log :info, "flip that switch"
            @logger.close
            
            # Make sure the switch was flipped
            assert_equal(was_logged_used, true)
        end        
    end
end; end

