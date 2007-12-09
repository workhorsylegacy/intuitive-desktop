
# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

require "#{path}/Namespace"

require 'pathname'

module ID; module Helpers
    class Color
        # Takes a hex string such as 'FF3388FF' and converts it to a RGBA array such as [1.0, 0.5, 0.5, 1.0]
        def self.hex_to_rgb(hex_string)
            # Just return white with full alpha
            return [1.0, 1.0, 1.0, 1.0] unless hex_string
            
            # Create a map of hex characters
            map = %w{ 0 1 2 3 4 5 6 7 8 9 0 A B C D E F }
            
            # Make sure the string is a valid hex number
            has_ox = hex_string[0..1].downcase == '0x'
            hex_string = hex_string[2..-1] if has_ox
            bad_string = false
            hex_string.split('').each { |n| unless map.include?(n.upcase); bad_string = true; end }
            
            if bad_string
                raise "The string '#{hex_string}' could not be converted from hexadecimal to integer."
            end
            
            r = unless hex_string[0..1] == nil
                eval("0x" + hex_string[0..1]) / 255.0
            else
                1.0
            end
            
            g = unless hex_string[2..3] == nil
                eval("0x" + hex_string[2..3]) / 255.0
            else
                1.0
            end

            b = unless hex_string[4..5] == nil
                eval("0x" + hex_string[4..5]) / 255.0
            else
                1.0
            end

            a = unless hex_string[6..7] == nil
                eval("0x" + hex_string[6..7]) / 255.0
            else
                1.0
            end

            [r, g, b, a]
        end
    end
end; end