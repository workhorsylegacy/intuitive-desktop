
# Move the path to the location of the current file
Dir.chdir(File.dirname(File.expand_path(__FILE__)))

# Require the base intuitive framework
require "../IntuitiveFramework/IntuitiveFramework"
require "TestHelper.rb"

# Require the unit test libs
require 'test/unit/testsuite'
require 'test/unit/ui/console/testrunner'
require 'test/unit/testcase'

# Helpers
require 'Helpers/TestBinding'
require 'Helpers/TestLogger'
require 'Helpers/TestProxy'
require 'Helpers/TestEasySocket'

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
require 'Controllers/TestSearchController'
require 'Controllers/TestUserController'

# Servers
require 'Servers/TestIdentityServer'
require 'Servers/TestCommunicationServer'
require 'Servers/TestProjectServer'

# Views
require 'Views/Base/TestMixinBindsChildrenToModels'
require 'Views/Base/TestMixinBindsToModel'
require 'Views/TestContainer'
require 'Views/TestView'

# Program
require 'TestProgram'

Thread.abort_on_exception = true

$ID_ENV = :test
ID::Config.load_config

    def helper_tests
        [ID::Helpers::TestBinding.suite,
        ID::Helpers::TestLogger.suite,
        ID::Helpers::TestEasySocket.suite,
        ID::Helpers::TestProxy.suite]
    end

    def model_test
        [ID::Models::TestBranch.suite,
        ID::Models::TestProject.suite,
        ID::Models::TestDocument.suite,
        ID::Models::TestUser.suite,
##        ID::Models::TestGroup.suite,
        ID::Models::Data::TestXmlModelCreator.suite]
    end

    def controller_tests
        [ID::Controllers::TestCommunicationController.suite,
##        ID::Controllers::TestDataController.suite,
        ID::Controllers::TestRevisionedFileSystemController.suite,
        ID::Controllers::TestSearchController.suite,
        ID::Controllers::TestUserController.suite]
    end

    def server_tests
        [ID::Servers::TestIdentityServer.suite,
        ID::Servers::TestProjectServer.suite,  #FIXME: Make this not explode the tests
        ID::Servers::TestCommunicationServer.suite]
    end
    
    def view_tests
        [ID::Views::Base::TestMixinBindsToModel.suite,
        ID::Views::Base::TestMixinBindsChildrenToModels.suite,
        ID::Views::TestView.suite,
        ID::Views::TestContainer.suite]
    end

    def desktop_test
        [ID::TestProgram.suite]
    end
    
    class TestSuite
        def self.suite
            master_suite = Test::Unit::TestSuite.new

#            [helper_tests,
#            model_test,
#            controller_tests,
#            server_tests,
#            view_tests,
#            desktop_test
#            ].each do |suite_set|
#                suite_set.each do |suite|
#                    master_suite << suite
#                end
#            end
            
            master_suite << ID::Helpers::TestEasySocket.suite
#            master_suite << ID::Servers::TestCommunicationServer.suite
#            master_suite << ID::Controllers::TestCommunicationController.suite
#            master_suite << ID::Helpers::TestProxy.suite
#            master_suite << ID::Servers::TestIdentityServer.suite
#             master_suite << ID::Servers::TestProjectServer.suite

            return master_suite
        end
    end 

Test::Unit::UI::Console::TestRunner.run(TestSuite)

