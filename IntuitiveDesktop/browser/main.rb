
=begin
  WARNING!!!!!!!!!!!!
  This Desktop Browser is a very ugly hack. It is just a test to create a mock desktop.
  It does not use the Intuitive Framework for anything but a few internal things. It does
  not accuratly represent how applications will be developed on the Intuitive Desktop.
  This is more like the 'traditional' way that Gtk/Ruby applications are made. Someone will
  rewrite this later when the Intuitive Framework has more controlls supported.
=end

Thread.abort_on_exception = true

# Move the path to the location of the current file
Dir.chdir(File.dirname(File.expand_path(__FILE__)))

require 'libglade2'
require "../../IntuitiveFramework/IntuitiveFramework.rb"
require $IntuitiveFramework_Models
require $IntuitiveFramework_Helpers
require $IntuitiveFramework_Controllers
require $IntuitiveFramework_Servers

$ID_ENV = :development
ID::Config.load_config

def start_server
    # Create the servers
    # FIXME: These should not be globals
    $communication_server = ID::Servers::CommunicationServer.new(:throw)
    $project_server = ID::Servers::ProjectServer.new(:throw)
    $project_server.clear_everything()
end

def setup_user_and_projects
    # Add a user
    public_key, private_key = ID::Models::EncryptionKey.make_public_and_private_keys
    user = ID::Models::User.new
    user.name = 'bobrick bobberton'
    user.public_universal_key = public_key.key.to_s
    user.private_key = private_key.key.to_s
    user.save!
    
    # Create the project
    branch = ID::Models::Branch.new('Map Example Trunk', user.public_universal_key)
    project = ID::Models::Project.new(branch, 'Map Example')
    project.description = "A simple map navigation program."
    
    document = ID::Models::Document.new(project, 'Model')
    document.data = File.new('../../examples/large_examples/maps/models.xml').read
    document.run_location = :client
    document.document_type = :model
    
    document = ID::Models::Document.new(project, 'State')
    document.data = File.new('../../examples/large_examples/maps/state.xml').read
    document.run_location = :client
    document.document_type = :state
    
    document = ID::Models::Document.new(project, 'View')
    document.data = File.new('../../examples/large_examples/maps/view.xml').read
    document.run_location = :client
    document.document_type = :view
    
    document = ID::Models::Document.new(project, 'Controller')
    document.data = File.new('../../examples/large_examples/maps/controller.rb').read
    document.run_location = :client
    document.document_type = :controller
    
    project.main_controller_class_name = "MapController"
    project.main_view_name = "main_window"
    ID::Controllers::DataController.save_revision(branch)
    
    # Advertise the project online
    $project_server.advertise_project_online(project.name, project.description, project.parent_branch.user_id,
                                             project.parent_branch.head_revision_number, project.project_number.to_s,
                                             project.parent_branch.branch_number.to_s)
                                             
    # Create the project
    branch = ID::Models::Branch.new('Clock Example Trunk', user.public_universal_key)
    project = ID::Models::Project.new(branch, 'Clock Example')
    project.description = "A simple clock program."
    
    document = ID::Models::Document.new(project, 'Model')
    document.data = File.new('../../examples/large_examples/clock/models.xml').read
    document.run_location = :client
    document.document_type = :model
    
    document = ID::Models::Document.new(project, 'State')
    document.data = File.new('../../examples/large_examples/clock/state.xml').read
    document.run_location = :client
    document.document_type = :state
    
    document = ID::Models::Document.new(project, 'View')
    document.data = File.new('../../examples/large_examples/clock/view.xml').read
    document.run_location = :client
    document.document_type = :view
    
    document = ID::Models::Document.new(project, 'Controller')
    document.data = File.new('../../examples/large_examples/clock/controller.rb').read
    document.run_location = :client
    document.document_type = :controller
    
    project.main_controller_class_name = "ClockController"
    project.main_view_name = "main_window"
    ID::Controllers::DataController.save_revision(branch)
    
    # Advertise the project online
    $project_server.advertise_project_online(project.name, project.description, project.parent_branch.user_id,
                                             project.parent_branch.head_revision_number, project.project_number.to_s,
                                             project.parent_branch.branch_number.to_s)
end

class Browser
  include GetText
  attr_reader :glade
  
  def initialize(path_or_data, root = nil, domain = nil, localedir = nil, flag = GladeXML::FILE)
    # Load the glade file and get references to its widgets
    bindtextdomain(domain, localedir, nil, "UTF-8")
    @glade = GladeXML.new(path_or_data, root, domain, localedir, flag) do |handler|
        method(handler)
    end
    
    @main_window = @glade.get_widget("main_window")
    @search_entry = @glade.get_widget("search_entry")
    @results_tree = @glade.get_widget("results_tree")
    
    # Setup the columns in the results tree
    column = Gtk::TreeViewColumn.new("Projects",
                    Gtk::CellRendererText.new,
                    { :text => 0})
    @results_tree.append_column(column)
    @results_tree.model = Gtk::ListStore.new(String)
    @result_to_project_map = {}
    
    @search_thread = nil
    @search_projects = nil
    @is_communicating = false
    
    # End the program when the window closes
    @main_window.signal_connect("destroy") do
        Gtk.main_quit
        
        $project_server.close()
        $communication_server.close()
        
        # Delete the data system
        FileUtils.rm_rf(ID::Config.data_dir) if File.directory?(ID::Config.data_dir)
    end
    
    # When a user enters text in the search_entry, search for that text
    @search_entry.signal_connect("changed") do |widget|
        search_string = @search_entry.text
        # Wait to start a new search if we are already communicating
        #loop { sleep(0.1) if @is_communicating }
        @search_thread.kill if @search_thread
        
        @search_thread = Thread.new(search_string) do |search_string|
            # Wait before actually starting the search
            sleep(1.0)
            
            # Search for the string
            @is_communicating = true
            @search_projects = $project_server.search_for_projects_online(search_string)
            @is_communicating = false
            
            project_names = Gtk::ListStore.new(String)
            @results_tree.model.clear
            @result_to_project_map.clear
            @search_projects.each do |project|
                @results_tree.model.append[0] = project[:name]
                @result_to_project_map[project[:name]] = project
            end
        end
    end
    
    @results_tree.signal_connect("row_activated") do |widget, path, column|
        if iter = widget.selection.selected
            name = iter[0]
            project = @result_to_project_map[name]
            server_address = $project_server.net_address
            
            program = ID::Program.new
            ID::Servers::ProjectServer.run_project(server_address,
                                              project[:revision], 
                                              project[:project_number].to_s,
                                              project[:branch_number],
                                              program)
            program.run
        end
    end
    
    @main_window.show_all
  end
end

# Start the project server
start_server

# Create a user and load the example map project into the data system
setup_user_and_projects

# Start the browser
PROG_PATH = "browser.glade"
PROG_NAME = "Intuitive Desktop Browser"
PROG_VER = "0.4.XX"
Gnome::Program.new(PROG_NAME, PROG_VER)
Browser.new(PROG_PATH, nil, PROG_NAME)
Gtk.main


=begin
    Things to fix:
    . Create a class called test desktop that holds the servers. 
    . Make sure the servers are completely isolated from the browser.
    . The SVGs are not transfered to the client with the Views, so the clock crashes.
    . Make the searching actually work, instead of returning everything
    . Have ProjectServer.run_project start the projects in a separate process
    . Programs seem to use some of the same data. IE: Multiple maps search to the same place!
=end


