
path = File.dirname(File.expand_path(__FILE__))
require "#{path}/Namespace"

module Controllers
  class SearchController
    def self.find_similar_strings(search_string, data_strings, limit = 10, ignore_common_words = false)
        # Create an array of common words to ignore
        common_words = %w{ the than they that a an is as at it are has have dont do who what when where why }
        
        # Break the search string into an array of lowercase words
        search_words = search_string.downcase.split
        search_words -= common_words if ignore_common_words
        
        # Get a table of data_strings with the number of matching search words
        matches = {}
        data_strings.each do |data_string|
            data_words = data_string.downcase.split
            count = search_words.length - (search_words - data_words).length
            next unless count > 0
                
            matches[count] = [] unless matches.has_key? count
            matches[count] << data_string
        end
        
        # Create an array with the limited number of search results
        results = []
        matches.keys.sort.reverse.each do |key|
            matches[key].each { |match| results << match }
        end
        results
    end
  end
end
