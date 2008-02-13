
module ID; module Models; module Data
        class TestXmlModelCreator < Test::Unit::TestCase
            def teardown
                ID::TestHelper.cleanup()
            end
            
            def test_model_from_xml
                # Get the XML for the model
                xml = 
<<XML
                      <Models>
                		<Table name="Dogs">
                			<Column name="name" type="string" allows_null="false" />
                			<Column name="age" type="integer" allows_null="false" />
                			<Value name="matt" age="24" />
                		</Table>
                      </Models>
XML
                
                # Create the active record model from the XML
                models = Models::Data::XmlModelCreator::models_from_xml_string(xml)
                class_dogs = models['Dogs']
                
                # Make sure the model class was created and has the correct properties
                assert_not_nil(Dogs)
                assert_same(Dogs, class_dogs)
                assert(Dogs.new.is_a?(ActiveRecord::Base))
                assert(Dogs.new.respond_to?("name="))
                assert(Dogs.new.respond_to?("age="))
                assert(Dogs.new.respond_to?("name"))
                assert(Dogs.new.respond_to?("age"))
                
                # Make sure the model has the correct values
                dog = Dogs.find(:first)
                assert_equal("matt", dog.name)
                assert_equal(24, dog.age)
                
                # Make sure we can add a new person
                dog = Dogs.new
                dog.name = "bobrick"
                dog.age = 33
                dog.save!
                
                dog = Dogs.find dog.id
                assert_equal("bobrick", dog.name)
                assert_equal(33, dog.age)                
            end
            
            def test_many_to_many
                # Get the XML for the models
                xml = 
<<XML
                      <Models>
                		<Table name="Author" has_and_belongs_to_many="Books">
                			<Column name="name" type="string" allows_null="false" />
                			<Value name="Neal Stephenson" />
                		</Table>
                		<Table name="Book" has_and_belongs_to_many="Authors">
                			<Column name="title" type="string" allows_null="false" />
                            <Column name="copyright" type="string" allows_null="false" />
                			<Value title="Cryptonomicon" copyright="1999" />
                            <Value title="Quicksilver" copyright="2003" />
                		</Table>
                		<Table name="AuthorsBooks">
                			<Column name="book_id" type="integer" allows_null="false" />
                            <Column name="author_id" type="integer" allows_null="false" />
                			<Value book_id="1" author_id="1" />
                            <Value book_id="2" author_id="1" />
                		</Table>
                      </Models>
XML
                
                # Create the active record model from the XML
                models = Models::Data::XmlModelCreator::models_from_xml_string(xml)
                class_authors = models['Author']
                class_books = models['Book']
                class_authors_books = models['AuthorsBooks']
                
                # Make sure the models were create
                assert_same(class_authors, Author)
                assert_same(class_books, Book)
                assert_same(class_authors_books, AuthorsBooks)
                
                # Make sure the values were added
                assert_equal("Neal Stephenson", Author.find(:first).name)
                assert_equal([{"Cryptonomicon" => "1999"}, {"Quicksilver" => "2003"}], Book.find(:all).collect{|b| {b.title => b.copyright} })
                assert_equal([{1 => 1}, {2 => 1}], AuthorsBooks.find(:all).collect{|b| {b.book_id => b.author_id} })
                
                # Make sure the tables have ids
                assert_equal(true, Author.find(:first).respond_to?(:id))
                assert_equal(true, Book.find(:first).respond_to?(:id))
                assert_equal(true, AuthorsBooks.find(:first).respond_to?(:id))
                
                # Make sure the relationships are connected
                assert_equal("Neal Stephenson", Book.find(:first).authors.first.name)
                assert_equal("Cryptonomicon", Author.find(:first).books.first.title)
            end
        end
end; end; end