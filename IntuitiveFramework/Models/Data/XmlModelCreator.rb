
module ID; module Models
    module Data
    
        # Reads an xml model and turns it into an ActiveRecord model.
        class XmlModelCreator
            def self.models_from_xml_string(xml_string)
                xml_document = REXML::Document.new(xml_string)
                xml_document.elements.each do |element|
                   return XmlModelCreator.models_from_xml(element)
                end
            end
            
            def self.models_from_xml(element)
                models = {}
                
                case element.name
                    when "Models"
                        m = []
                        element.elements.each do |e|
                            m << e if e.name == "Table"
                        end
                        m = create_active_record_models_from_xml(m)
                        m.each do |model|
                            models[model.name] = model
                        end
                    else raise "The element 'Models' was expected, not '#{element.name}'."
                end
                
                models
            end
            
            def self.models_from_documents(documents)
                models = {}
                
                documents.each do |document|
                    models.merge!(models_from_xml_string(document.data))
                end
                
                models
            end
        end
        
        class TablePlan
          attr_accessor :name, :id, :has_and_belongs_to_many, :has_many, :has_one, :belongs_to, :column_plans, :value_plans

          def self.from_xml(element)
            # Make sure we have the needed element
            raise "The element is not a 'Table'." if element.name != "Table"
        
            # Make sure the element has the nessesary attribtues
            raise "The element 'Table' is missing the attribute 'name'." unless element.attributes['name']
        
            # Get the attributes
            new_table_plan = TablePlan.new
            new_table_plan.name = element.attributes['name']
            new_table_plan.id = element.attributes['id'] || true
            new_table_plan.has_and_belongs_to_many = element.attributes['has_and_belongs_to_many']
            new_table_plan.has_many = element.attributes['has_many']
            new_table_plan.has_one = element.attributes['has_one']
            new_table_plan.belongs_to = element.attributes['belongs_to']
            new_table_plan.column_plans = []
            new_table_plan.value_plans = []
            
            # Convert a string like 'false' into the real bool
            new_table_plan.id = new_table_plan.id.to_b if new_table_plan.id.is_a? String
        
            # Read the Column and Value sub elements
            element.elements.each { |e|
              case e.name
                when "Column": new_table_plan.column_plans << ColumnPlan::from_xml(e)
                when "Value": new_table_plan.value_plans << ValuePlan::from_xml(new_table_plan, e)
                else raise "The element 'Table' does not know how to use the sub element 'e.name'."
              end
            }
        
            new_table_plan
          end
        end
        
        class ColumnPlan
          attr_accessor :name, :type, :allows_null
        
          def self.from_xml(element)
            # Make sure we have the needed element
            raise "The element is not a 'Column'." if element.name != "Column"
        
            # Make sure the element has the nessesary attribtues
            raise "The element 'Column' is missing the attribute 'name'." unless element.attributes['name']
            raise "The element 'Column' is missing the attribute 'type'." unless element.attributes['type']
            raise "The element 'Column' is missing the attribute 'allows_null'." unless element.attributes['allows_null']
        
            # Make sure there are no sub element
            #NOTE: Does not seem to be a .length for this, so we just iterate through to see if there are any
            element.elements.each {|z|
              raise "The 'Column' element does not expect any sub elements."
            }
        
            # Get the attributes
            new_column_plan = ColumnPlan.new
            new_column_plan.name = element.attributes['name']
            new_column_plan.type = element.attributes['type']
            new_column_plan.allows_null = element.attributes['allows_null']
        
            new_column_plan
          end
        end
        
        class ValuePlan
          attr_accessor :values
        
          def self.from_xml(parent_table_plan, element)
            # Make sure we have the needed element
            raise "The element is not a 'Value'." if element.name != "Value"
        
            # Make sure the element has the nessesary attribtues
            parent_table_plan.column_plans.each do |column_plans|
                message = "The Value for the Table '#{parent_table_plan.name}' is missing the attribute '#{column_plans.name}'."
              raise message unless element.attributes["#{column_plans.name}"]
            end
        
            # Make sure there are no sub element
            #NOTE: Does not seem to be a .length for this, so we just iterate through to see if there are any
            element.elements.each {|z|
              raise "The Value for the Table '#{parent_table_plan.name}' cannot have any sub elements."
            }
        
            # Add values
            new_value_plan = ValuePlan.new
            new_value_plan.values = {}
            element.attributes.each { |key, value|
              new_value_plan.values[key] = value
            }
        
            new_value_plan
          end
        end
    end
end

# FIXME: This needs to be in the base namespace so any models created will start from the base namespace too.
def create_active_record_models_from_xml(xml_element_tables)

	FileUtils.mkdir($IntuitiveFramework + "/temporary_tables/") unless File.exist?($IntuitiveFramework + "/temporary_tables/")

    # Create a folder for the databases
    file_name = nil
    loop do
        dir_name = $IntuitiveFramework + "/temporary_tables/#{rand(2**32)}/"
        unless File.directory? dir_name
            Dir.mkdir dir_name
            file_name = "#{dir_name}temp.sqlite"
            break
        end
    end
                
  # Read the xml tables into table plans
  table_plans = xml_element_tables.collect{ |e| Models::Data::TablePlan::from_xml(e) }

    # Get the connection info for a new database
    connection_format =  { :adapter => 'sqlite3', :database => file_name }
            
    # Create a temporary connection to the new database
    ActiveRecord::Base.establish_connection(connection_format)

  # Create a table in the database using a migration from the XML
  table_plans.each do |table_plan|
      ActiveRecord::Migration.create_table(table_plan.name.tableize.to_sym, :temporary => false, :id => table_plan.id) { |table|
        # Add columns
        table_plan.column_plans.each { |column_plan|
          table.column(column_plan.name, column_plan.type, :null => column_plan.allows_null)
        }
      }
    end

    # Break the temporary connection
    ActiveRecord::Base.remove_connection
    
  # Create the active record class
  model_classes = []
  table_plans.each do |table_plan|
      eval("class #{table_plan.name} < ActiveRecord::Base; @@bindings=[]; @@database_file_reference_counter=nil; def self.database_file_reference_counter=(value); @@database_file_reference_counter=value; end; def self.bindings; @@bindings; end; end")
      model_class = eval("#{table_plan.name}")
      model_class.has_and_belongs_to_many(table_plan.has_and_belongs_to_many.tableize.to_sym) if table_plan.has_and_belongs_to_many
      model_class.has_many(table_plan.has_many.tableize.to_sym) if table_plan.has_many
      model_class.has_one(table_plan.has_one.tableize.to_sym) if table_plan.has_one
      model_class.belongs_to(table_plan.belongs_to.tableize.to_sym) if table_plan.belongs_to
      model_class.establish_connection(connection_format)
      
      model_classes << model_class
      
      # Add values
        table_plan.value_plans.each { |value_plan|
            model_class.create(value_plan.values)
        }
  end
  
  # Have the database file deleted when this object is GCed
  database_file_reference_counter = Object.new
    ObjectSpace.define_finalizer(database_file_reference_counter) {
         begin
            # Remove the temporary database file and directory
                File.delete(file_name)
                Dir.delete(File.dirname(file_name))
            rescue Exception => e
                puts e.message
            end
    }
    
    # Have each Model class save a reference to the object that 
    # will delete the database file when it is GCed
  model_classes.each do |model_class|
     model_class.database_file_reference_counter = database_file_reference_counter
  end

  model_classes
end; end
