
=begin
  WARNING!!!!!!!!!!!!
  This Desktop Browser is a very ugly hack. It is just a test to create a mock desktop.
  It does not use the Intuitive Frawework for anything but a few internal things. It does
  not accuratly represent how applications will be developed on the Intuitive Desktop.
  This is more like the 'traditional' way that Gtk/Ruby applications are made. Someone will
  rewrite this later when the Intuitive Framework has more controlls supported.
=end

Thread.abort_on_exception = true

# Move the path to the location of the current file
Dir.chdir(File.dirname(File.expand_path(__FILE__)))

require 'libglade2'
require "../IntuitiveFramework/IntuitiveFramework.rb"
require $IntuitiveFramework_Servers

class Desktop
    include GetText
    attr_reader :glade
  
    def initialize(path_or_data, root = nil, domain = nil, localedir = nil, flag = GladeXML::FILE)
        # Load the glade file and get references to its widgets
        bindtextdomain(domain, localedir, nil, "UTF-8")
        @glade = GladeXML.new(path_or_data, root, domain, localedir, flag) {|handler| method(handler)}
        
        @shutdown_button = @glade.get_widget("shutdown_button")
        @shutdown_button.signal_connect("button_press_event") do
            Gtk.main_quit
        end
        
        @identity_bulge = @glade.get_widget("identity_bulge")
        @system_bulge = @glade.get_widget("system_bulge")
        @browser_bulge = @glade.get_widget("browser_bulge")
        @workflow_bulge = @glade.get_widget("workflow_bulge")
=begin
        [@identity_bulge,
        @system_bulge,
        @browser_bulge,
        @workflow_bulge].each do |bulge| 
            bulge.signal_connect('expose-event') do |widget, event|
                self.draw(widget)
            end
        end
=end
        @identity_bulge.move(*top_right_close_position)
        @system_bulge.move(*top_left_close_position)
        @browser_bulge.move(*bottom_left_close_position)
        @workflow_bulge.move(*botton_right_close_position)

        @identity_bulge.signal_connect("enter_notify_event") { |widget, event| @identity_bulge.move(*top_right_open_position) }
        @system_bulge.signal_connect("enter_notify_event") { |widget, event| @system_bulge.move(*top_left_open_position) }
        @browser_bulge.signal_connect("enter_notify_event") { |widget, event| @browser_bulge.move(*bottom_left_open_position) }
        @workflow_bulge.signal_connect("enter_notify_event") { |widget, event| @workflow_bulge.move(*botton_right_open_position) }

        @identity_bulge.signal_connect("leave_notify_event") do |widget, event|
            next if event.x > 0 && event.y < widget.size.last
            @identity_bulge.move(*top_right_close_position)
        end
        @system_bulge.signal_connect("leave_notify_event") do |widget, event|
            next if event.x < widget.size.first && event.y < widget.size.last    
            @system_bulge.move(*top_left_close_position)
        end
        @browser_bulge.signal_connect("leave_notify_event") do |widget, event|
            next if event.x < widget.size.first && event.y > 0
            @browser_bulge.move(*bottom_left_close_position)
        end
        @workflow_bulge.signal_connect("leave_notify_event") do |widget, event|
            next if event.x > 0 && event.y > 0
            @workflow_bulge.move(*botton_right_close_position)
        end

        [@identity_bulge,
        @system_bulge,
        @browser_bulge,
        @workflow_bulge].each do |bulge|
            bulge.show_all
            bulge.keep_above = true
        end
    end
    
    def botton_right_close_position
        [Gdk::Screen.default.width - 50, Gdk::Screen.default.height - 50]
    end
    
    def botton_right_open_position
        [Gdk::Screen.default.width - 125, Gdk::Screen.default.height - 125]
    end    
    
    def top_right_close_position
        [Gdk::Screen.default.width - 50, - 150]
    end
    
    def top_right_open_position
        [Gdk::Screen.default.width - 125, - 75]
    end    
    
    def bottom_left_close_position
        [- 150, Gdk::Screen.default.height - 50]
    end

    def bottom_left_open_position
        [- 75, Gdk::Screen.default.height - 125]
    end

    def top_left_close_position
        [- 150, - 150]
    end
    
    def top_left_open_position
        [- 75, - 75]
    end
=begin
    def draw(window)
        shaped_bitmap = Gdk::Pixmap.new(nil, window.size.first, window.size.last, 1)
        cr = shaped_bitmap.create_cairo_context
        cr.set_source_rgba(0, 1, 0, 1)
        cr.rectangle(50, 50, 50, 50)
        cr.fill
        #Apply input mask
        window.input_shape_combine_mask(shaped_bitmap, 0, 0)
    end
=end
end


# Start the browser
PROG_NAME = "IntuitiveDesktop"
PROG_PATH = "Desktop.glade"
PROG_VER = "0.4.50"
Gnome::Program.new(PROG_NAME, PROG_VER)

Desktop.new(PROG_PATH, nil, PROG_NAME)

Gtk.main
