

module ID; module Controllers
    class TestRevisionedFileSystemController < Test::Unit::TestCase
        def setup
            @test_folder = "test_dir/"
            
            FileUtils.rm_rf(@test_folder) if File.directory?(@test_folder)
            Dir.mkdir(@test_folder)
        end
    
        def teardown
            FileUtils.rm_rf(@test_folder) if File.directory?(@test_folder)
        end
    
        def test_diff_folder_simple
            # Test a simple diff
            Dir.mkdir("#{@test_folder}original")
            Dir.mkdir("#{@test_folder}original/too")
            File.open("#{@test_folder}original/too/one", 'w') { |f| f.write("things to buy for supper:\n 1. butter\n 2. crisco\n 3. vegtable oil") }
            File.open("#{@test_folder}original/too/two", 'w') { |f| f.write("supper") }
            File.open("#{@test_folder}original/too/three", 'w') { |f| f.write("expecting 3 guests") }
            
            FileUtils.cp_r("#{@test_folder}original", "#{@test_folder}changed")
            File.open("#{@test_folder}changed/too/one", 'w') { |f| f.write("things to buy for dinner:\n 1. butter\n 2. crisco\n 3. motor oil") }
            File.open("#{@test_folder}changed/too/two", 'w') { |f| f.write("dinner") }
            
            RevisionedFileSystemController.diff_folders("#{@test_folder}original", "#{@test_folder}changed", "#{@test_folder}deltas")
            
            # Make sure the files were diffed correctly
            assert_equal(true, File.directory?("#{@test_folder}deltas"))
            assert_equal(true, File.directory?("#{@test_folder}deltas/0"))
            assert_equal(true, File.directory?("#{@test_folder}deltas/0/too"))
            File.open("#{@test_folder}deltas/0/too/one", 'r') do |f|
                assert(f.read.length > 0)
            end
            File.open("#{@test_folder}deltas/0/too/two", 'r') do |f|
                assert(f.read.length)
            end
            assert_equal(false, File.file?("#{@test_folder}deltas/0/too/three"))
        end
        
        def test_diff_folder_new_files
            # Test a simple diff
            Dir.mkdir("#{@test_folder}original")
            
            FileUtils.cp_r("#{@test_folder}original", "#{@test_folder}changed")
            RevisionedFileSystemController.new_directory("#{@test_folder}changed/", "#{@test_folder}changed/too/")
            RevisionedFileSystemController.new_file("#{@test_folder}changed/", "#{@test_folder}changed/too/three")
            File.open("#{@test_folder}changed/too/three", 'w') { |f| f.write("bobrick is bringing meatloaf!") }        
            
            RevisionedFileSystemController.diff_folders("#{@test_folder}original", "#{@test_folder}changed", "#{@test_folder}deltas")
            
            # Make sure the files were diffed correctly
            assert(File.directory?("#{@test_folder}deltas"))
            assert(File.directory?("#{@test_folder}deltas/0"))
            assert(File.directory?("#{@test_folder}deltas/0/too"))
            File.open("#{@test_folder}deltas/0/too/three", 'r') do |f|
                assert(f.read.length)
            end
            assert_equal(true, FileUtils.cmp("#{@test_folder}deltas/0/.file_system_changes", "#{@test_folder}changed/.file_system_changes"))
        end
        
        def test_diff_folder_deleted_files
            # Test a simple diff
            Dir.mkdir("#{@test_folder}original")
            File.open("#{@test_folder}original/zero", 'w') { |f| f.write("zero of doom") }
            Dir.mkdir("#{@test_folder}original/too")
            File.open("#{@test_folder}original/too/one", 'w') { |f| f.write("things to buy for supper:\n 1. butter\n 2. crisco\n 3. vegtable oil") }
            File.open("#{@test_folder}original/too/two", 'w') { |f| f.write("supper") }
            Dir.mkdir("#{@test_folder}original/dir/")
            File.open("#{@test_folder}original/dir/another", 'w') { |f| f.write("another") }
            
            FileUtils.cp_r("#{@test_folder}original", "#{@test_folder}changed")
            RevisionedFileSystemController.delete_file("#{@test_folder}changed/", "#{@test_folder}changed/zero")
            RevisionedFileSystemController.delete_directory("#{@test_folder}changed/", "#{@test_folder}changed/too")
            RevisionedFileSystemController.delete_file("#{@test_folder}changed/", "#{@test_folder}changed/dir/another")
            
            RevisionedFileSystemController.diff_folders("#{@test_folder}original", "#{@test_folder}changed", "#{@test_folder}deltas")
            
            # Make sure the files were diffed correctly
            assert(File.directory?("#{@test_folder}deltas"))
            assert(File.directory?("#{@test_folder}deltas/0"))
            assert_equal(false, File.directory?("#{@test_folder}deltas/0/zero"))
            assert_equal(false, File.directory?("#{@test_folder}deltas/0/too"))
            assert_equal(false, File.file?("#{@test_folder}deltas/0/too/one"))
            assert_equal(false, File.file?("#{@test_folder}deltas/0/too/two"))
            assert_equal(true, File.directory?("#{@test_folder}deltas/0/dir"))
            assert_equal(false, File.file?("#{@test_folder}deltas/0/dir/another"))
            
            assert_equal(true, FileUtils.cmp("#{@test_folder}deltas/0/.file_system_changes", "#{@test_folder}changed/.file_system_changes"))
        end
        
        def test_diff_folder_move_files
            # Test a simple diff
            Dir.mkdir("#{@test_folder}original")
            File.open("#{@test_folder}original/zero", 'w') { |f| f.write("zero of doom") }
            Dir.mkdir("#{@test_folder}original/too")
            File.open("#{@test_folder}original/too/one", 'w') { |f| f.write("things to buy for supper:\n 1. butter\n 2. crisco\n 3. vegtable oil") }
            File.open("#{@test_folder}original/too/two", 'w') { |f| f.write("supper") }
            Dir.mkdir("#{@test_folder}original/dir/")
            File.open("#{@test_folder}original/dir/another", 'w') { |f| f.write("another") }
            
            FileUtils.cp_r("#{@test_folder}original", "#{@test_folder}changed")
            RevisionedFileSystemController.new_directory("#{@test_folder}changed/", "#{@test_folder}changed/toot")
            RevisionedFileSystemController.move_directory("#{@test_folder}changed/", "#{@test_folder}changed/too", "#{@test_folder}changed/toot/another")
            RevisionedFileSystemController.move_file("#{@test_folder}changed/", "#{@test_folder}changed/dir/another", "#{@test_folder}changed/toot/another/another_file")
            
            RevisionedFileSystemController.diff_folders("#{@test_folder}original", "#{@test_folder}changed", "#{@test_folder}deltas")
            
            # Make sure the files were diffed correctly
            assert_equal(true, File.directory?("#{@test_folder}deltas"))
            assert_equal(true, File.directory?("#{@test_folder}deltas/0"))
            assert_equal(false, File.directory?("#{@test_folder}deltas/0/too"))
            assert_equal(false, File.file?("#{@test_folder}deltas/0/dir/another"))
            
    #        assert_equal(true, File.directory?("#{@test_folder}deltas/0/zero/"))
            assert_equal(true, File.directory?("#{@test_folder}deltas/0/toot"))
            assert_equal(true, File.directory?("#{@test_folder}deltas/0/toot/another"))
    #        assert_equal(true, File.file?("#{@test_folder}deltas/0/toot/another/one"))
    #        assert_equal(true, File.file?("#{@test_folder}deltas/0/toot/another/two"))
            assert_equal(true, File.directory?("#{@test_folder}deltas/0/dir"))
    #        assert_equal(true, File.file?("#{@test_folder}deltas/0/toot/another/another_file"))
            
            assert_equal(true, FileUtils.cmp("#{@test_folder}deltas/0/.file_system_changes", "#{@test_folder}changed/.file_system_changes"))
        end
    
        def test_patch_folder_simple
            # Test a simple patch
            Dir.mkdir("#{@test_folder}original")
            
            Dir.mkdir("#{@test_folder}change_one")
            RevisionedFileSystemController.new_directory("#{@test_folder}change_one", "#{@test_folder}change_one/too")
            RevisionedFileSystemController.new_file("#{@test_folder}change_one", "#{@test_folder}change_one/too/one")
            File.open("#{@test_folder}change_one/too/one", 'w') { |f| f.write("things to buy for dinner:\n 1. butter\n 2. crisco\n 3. motor oil") }
            RevisionedFileSystemController.new_file("#{@test_folder}change_one", "#{@test_folder}change_one/too/two")
            File.open("#{@test_folder}change_one/too/two", 'w') { |f| f.write("dinner") }
            RevisionedFileSystemController.new_file("#{@test_folder}change_one", "#{@test_folder}change_one/too/three")
            File.open("#{@test_folder}change_one/too/three", 'w') { |f| f.write("expecting 3 guests") }
            
            RevisionedFileSystemController.diff_folders("#{@test_folder}original", "#{@test_folder}change_one", "#{@test_folder}deltas")
            
            FileUtils.cp_r("#{@test_folder}change_one", "#{@test_folder}change_two")
            File.delete("#{@test_folder}change_two/.file_system_changes") if File.file?("#{@test_folder}change_two/.file_system_changes")
            File.open("#{@test_folder}change_two/too/one", 'w') { |f| f.write("things to buy for supper:\n 1. butter\n 2. crisco\n 3. vegtable oil") }
            File.open("#{@test_folder}change_two/too/two", 'w') { |f| f.write("supper") }
            
            RevisionedFileSystemController.diff_folders("#{@test_folder}change_one", "#{@test_folder}change_two", "#{@test_folder}deltas")
            
            RevisionedFileSystemController.patch_folders("#{@test_folder}deltas", "#{@test_folder}patched")
            
            # Make sure the files were diffed correctly
            assert(File.directory?("#{@test_folder}patched"))
            assert(File.directory?("#{@test_folder}patched/too"))
            File.open("#{@test_folder}patched/too/one", 'r') do |f|
                assert_equal("things to buy for supper:\n 1. butter\n 2. crisco\n 3. vegtable oil", f.read)
            end
            File.open("#{@test_folder}patched/too/two", 'r') do |f|
                assert_equal("supper", f.read)
            end
            File.open("#{@test_folder}patched/too/three", 'r') do |f|
                assert_equal("expecting 3 guests", f.read)
            end
        end
    
        def test_patch_folder_new_files
            # Test a patch with new files
            Dir.mkdir("#{@test_folder}original")
            
            Dir.mkdir("#{@test_folder}change_one")
            RevisionedFileSystemController.new_directory("#{@test_folder}change_one", "#{@test_folder}change_one/too")
            RevisionedFileSystemController.new_file("#{@test_folder}change_one", "#{@test_folder}change_one/too/one")
            File.open("#{@test_folder}change_one/too/one", 'w') { |f| f.write("things to buy for dinner:\n 1. butter\n 2. crisco\n 3. motor oil") }
            RevisionedFileSystemController.new_file("#{@test_folder}change_one", "#{@test_folder}change_one/too/two")
            File.open("#{@test_folder}change_one/too/two", 'w') { |f| f.write("dinner") }
            RevisionedFileSystemController.new_file("#{@test_folder}change_one", "#{@test_folder}change_one/too/three")
            File.open("#{@test_folder}change_one/too/three", 'w') { |f| f.write("expecting 3 guests") }
            
            RevisionedFileSystemController.diff_folders("#{@test_folder}original", "#{@test_folder}change_one", "#{@test_folder}deltas")
            RevisionedFileSystemController.patch_folders("#{@test_folder}deltas", "#{@test_folder}patched")
            
            # Make sure the files were diffed correctly
            assert(File.directory?("#{@test_folder}patched"))
            assert(File.directory?("#{@test_folder}patched/too"))
            File.open("#{@test_folder}patched/too/one", 'r') do |f|
                assert_equal("things to buy for dinner:\n 1. butter\n 2. crisco\n 3. motor oil", f.read)
            end
            File.open("#{@test_folder}patched/too/two", 'r') do |f|
                assert_equal("dinner", f.read)
            end
            File.open("#{@test_folder}patched/too/three", 'r') do |f|
                assert_equal("expecting 3 guests", f.read)
            end
        end
    
        def test_patch_folder_deleted_files
            # Test a patch with deleted files
            Dir.mkdir("#{@test_folder}original")
            
            Dir.mkdir("#{@test_folder}change_one")
            RevisionedFileSystemController.new_file("#{@test_folder}change_one/", "#{@test_folder}change_one/zero")
            File.open("#{@test_folder}change_one/zero", 'w') { |f| f.write("zero of doom") }
            RevisionedFileSystemController.new_directory("#{@test_folder}change_one/", "#{@test_folder}change_one/too/")
            RevisionedFileSystemController.new_file("#{@test_folder}change_one/", "#{@test_folder}change_one/too/one")
            File.open("#{@test_folder}change_one/too/one", 'w') { |f| f.write("things to buy for supper:\n 1. butter\n 2. crisco\n 3. vegtable oil") }
            RevisionedFileSystemController.new_file("#{@test_folder}change_one/", "#{@test_folder}change_one/too/two")
            File.open("#{@test_folder}change_one/too/two", 'w') { |f| f.write("supper") }
            RevisionedFileSystemController.new_directory("#{@test_folder}change_one/", "#{@test_folder}change_one/dir/")
            RevisionedFileSystemController.new_file("#{@test_folder}change_one/", "#{@test_folder}change_one/dir/another")
            File.open("#{@test_folder}change_one/dir/another", 'w') { |f| f.write("another") }
            
            RevisionedFileSystemController.diff_folders("#{@test_folder}original", "#{@test_folder}change_one", "#{@test_folder}deltas")
            
            FileUtils.cp_r("#{@test_folder}change_one", "#{@test_folder}change_two")
            File.delete("#{@test_folder}change_two/.file_system_changes") if File.file?("#{@test_folder}change_two/.file_system_changes")
            RevisionedFileSystemController.delete_file("#{@test_folder}change_two/", "#{@test_folder}change_two/zero")
            RevisionedFileSystemController.delete_directory("#{@test_folder}change_two/", "#{@test_folder}change_two/too")
            RevisionedFileSystemController.delete_file("#{@test_folder}change_two/", "#{@test_folder}change_two/dir/another")
            
            RevisionedFileSystemController.diff_folders("#{@test_folder}change_one", "#{@test_folder}change_two", "#{@test_folder}deltas")
            RevisionedFileSystemController.patch_folders("#{@test_folder}deltas", "#{@test_folder}patched")
            
            # Make sure the files were diffed correctly
            assert_equal(true, File.directory?("#{@test_folder}patched/"))
            assert_equal(true, File.directory?("#{@test_folder}patched/dir/"))
            assert_equal(false, File.file?("#{@test_folder}patched/zero"))
            assert_equal(false, File.file?("#{@test_folder}patched/too/"))
            assert_equal(false, File.directory?("#{@test_folder}patched/dir/another"))
        end
    
        def test_patch_folder_move_files
            # Test a patch with moved files
            Dir.mkdir("#{@test_folder}original")
            
            Dir.mkdir("#{@test_folder}change_one")
            File.open("#{@test_folder}change_one/zero", 'w') { |f| f.write("zero of doom") }
            RevisionedFileSystemController.new_directory("#{@test_folder}change_one", "#{@test_folder}change_one/too/")
            RevisionedFileSystemController.new_file("#{@test_folder}change_one", "#{@test_folder}change_one/too/one")
            File.open("#{@test_folder}change_one/too/one", 'w') { |f| f.write("things to buy for supper:\n 1. butter\n 2. crisco\n 3. vegtable oil") }
            RevisionedFileSystemController.new_file("#{@test_folder}change_one", "#{@test_folder}change_one/too/two")
            File.open("#{@test_folder}change_one/too/two", 'w') { |f| f.write("supper") }
            RevisionedFileSystemController.new_directory("#{@test_folder}change_one", "#{@test_folder}change_one/dir/")
            RevisionedFileSystemController.new_file("#{@test_folder}change_one", "#{@test_folder}change_one/dir/another")
            File.open("#{@test_folder}change_one/dir/another", 'w') { |f| f.write("another") }
            
            RevisionedFileSystemController.diff_folders("#{@test_folder}original", "#{@test_folder}change_one", "#{@test_folder}deltas")
            
            FileUtils.cp_r("#{@test_folder}change_one", "#{@test_folder}change_two")
            File.delete("#{@test_folder}change_two/.file_system_changes") if File.file?("#{@test_folder}change_two/.file_system_changes")
            RevisionedFileSystemController.new_directory("#{@test_folder}change_two/", "#{@test_folder}change_two/toot")
            RevisionedFileSystemController.move_directory("#{@test_folder}change_two/", "#{@test_folder}change_two/too", "#{@test_folder}change_two/toot/another")
            RevisionedFileSystemController.move_file("#{@test_folder}change_two/", "#{@test_folder}change_two/dir/another", "#{@test_folder}change_two/toot/another/another_file")
            
            RevisionedFileSystemController.diff_folders("#{@test_folder}change_one", "#{@test_folder}change_two", "#{@test_folder}deltas")
            RevisionedFileSystemController.patch_folders("#{@test_folder}deltas", "#{@test_folder}patched")
    
            # Make sure the files were diffed correctly
            assert_equal(true, File.directory?("#{@test_folder}patched/"))
            assert_equal(false, File.directory?("#{@test_folder}patched/too/"))
            assert_equal(false, File.file?("#{@test_folder}patched/too/one"))
            assert_equal(false, File.file?("#{@test_folder}patched/too/two"))
            assert_equal(true, File.directory?("#{@test_folder}patched/dir/"))
            assert_equal(false, File.file?("#{@test_folder}patched/dir/another"))
            assert_equal(true, File.directory?("#{@test_folder}patched/toot/"))
            assert_equal(true, File.directory?("#{@test_folder}patched/toot/another/"))
            assert_equal(true, File.file?("#{@test_folder}patched/toot/another/another_file"))
            assert_equal(true, File.file?("#{@test_folder}patched/toot/another/one"))
            assert_equal(true, File.file?("#{@test_folder}patched/toot/another/two"))
            assert_equal(true, File.file?("#{@test_folder}patched/toot/another/another_file"))
            
            assert_equal(true, FileUtils.cmp("#{@test_folder}deltas/0/.file_system_changes", "#{@test_folder}change_one/.file_system_changes"))
            assert_equal(true, FileUtils.cmp("#{@test_folder}deltas/1/.file_system_changes", "#{@test_folder}change_two/.file_system_changes"))
        end
    end
end; end
