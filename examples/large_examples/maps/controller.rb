
require $IntuitiveFramework_Controllers


# Shows a basic map with some interstate highways drawn from Models
class MapController < Controllers::DocumentController
    def initialize(models)
        super(models)
        
        @interstates_visible = false
    end

    def find_location_address(place_to_find)
        # Create an array of common words to ignore
        common_names = %w{ the than they that a an is as at it are has have }
        common_names.concat(%w{ st street ave avenue apt apartment interstate highway })
        
        # Break the place name into an array of lowercase words
        search_words = place_to_find.downcase.split - common_names
                
        # Get an array of all the places
        locations = @models['Locations'].find(:all).collect { |loc| [loc.name.downcase, loc.id] }
        
        # Get a table of places with the number of matching words
        matches = {}
        locations.each do |location, id|
            count = (location.split & search_words).length
            next unless count > 0
            
            matches[count] = [] unless matches.has_key? count
            matches[count] << [location, id]
        end
        
        # Return an empty array if there were no matches
        return [] unless matches.length > 0
        
        # Grabs the ids of locations that have the most matches
        matched_ids = matches[matches.keys.sort.last].collect { |loc, id| id}.join(', ')
        
        # Return an array of matching models
        @models['Locations'].find(:all, :conditions => "id in(#{matched_ids})")
    end

    def toggle_interstates
        # Reverse the visibility
        @interstates_visible = !@interstates_visible
        
        # Just return if the interstates are not visible
        return unless @interstates_visible
        
        interstates = @models['Interstate'].find(:all)
    end
end




