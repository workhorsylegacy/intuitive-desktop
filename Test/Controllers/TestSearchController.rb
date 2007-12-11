

module ID; module Controllers
    class TestSearchController < Test::Unit::TestCase
        def teardown
            ID::TestHelper.cleanup()
        end
        
        def test_find_similar_string
            # Create the database of strings
            data_strings = ["three flavors ice cream",
                            "ThRee RinG CIRCus",
                            "septic city",
                            "port 9",
                            "ThREE Ring Flavors"]
                            
            # Search for a string and get the results
            search_string = "three"
            results = SearchController.find_similar_strings(search_string, data_strings)
            
            # Make sure we got the strings
            assert_equal(3, results.length)
            assert(results.include?("three flavors ice cream"))
            assert(results.include?("ThRee RinG CIRCus"))
            assert(results.include?("ThREE Ring Flavors"))
            
            # Make sure the most similar is first
            search_string = "flavors ring three"
            results = SearchController.find_similar_strings(search_string, data_strings)
            assert_equal("ThREE Ring Flavors", results[0])
            assert_equal(["three flavors ice cream", "ThRee RinG CIRCus"], results[1..2])
            
            # Make sure failed searches return empty arrays
            search_string = "not anywhere"
            results = SearchController.find_similar_strings(search_string, data_strings)
            assert_equal(0, results.length)
        end
    end
end; end
