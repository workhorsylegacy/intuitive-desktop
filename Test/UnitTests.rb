
# Move the path to the location of the current file
Dir.chdir(File.dirname(File.expand_path(__FILE__)))

# Require the base intuitive framework
require "../IntuitiveFramework/IntuitiveFramework"

# Require the unit test libs
require 'test/unit/testsuite'
require 'test/unit/ui/console/testrunner'
require 'test/unit/testcase'

## Helpers
require 'Helpers/TestBinding'
require 'Helpers/TestLogger'
require 'Helpers/TestProxy'

# Models
require 'Models/TestBranch'
require 'Models/TestDocument'
require 'Models/TestGroup'
require 'Models/TestProject'
require 'Models/TestUser'
require 'Models/Data/TestXmlModelCreator'

# Controllers
require 'Controllers/TestCommunicationController'
require 'Controllers/TestDataController'
require 'Controllers/TestRevisionedFileSystemController'
require 'Controllers/TestUserController'

# Servers
require 'Servers/TestIdentityServer'

# Views
require 'Views/Base/TestMixinBindsChildrenToModels'
require 'Views/Base/TestMixinBindsToModel'
require 'Views/TestContainer'
require 'Views/TestView'

# Desktop
require 'TestProgram'

Thread.abort_on_exception = true

    def helper_tests
        [Helpers::TestBinding.suite,
        Helpers::TestLogger.suite,
        Helpers::TestProxy.suite]
    end

    def model_test
        [Models::TestBranch.suite,
        Models::TestProject.suite,
        Models::TestDocument.suite,
        Models::TestUser.suite,
        #Models::TestGroup.suite,
        Models::Data::TestXmlModelCreator.suite]
    end

    def controller_tests
        [Controllers::TestCommunicationController.suite,
        Controllers::TestDataController.suite,
        Controllers::TestRevisionedFileSystemController.suite,
        Controllers::TestUserController.suite]
    end

    def server_tests
        [Servers::TestIdentityServer.suite]
    end
    
    def view_tests
        [Views::Base::TestMixinBindsToModel.suite,
        Views::Base::TestMixinBindsChildrenToModels.suite,
        Views::TestView.suite,
        Views::TestContainer.suite]
    end

    def desktop_test
        [TestProgram.suite]
    end
    
    class TestSuite
        def self.suite
            master_suite = Test::Unit::TestSuite.new
            
            [helper_tests,
            model_test,
            controller_tests,
            server_tests,
            view_tests,
            desktop_test].each do |suite_set|
                suite_set.each do |suite|
                    master_suite << suite
                end
            end
            
            return master_suite
        end
    end 

Test::Unit::UI::Console::TestRunner.run(TestSuite)

