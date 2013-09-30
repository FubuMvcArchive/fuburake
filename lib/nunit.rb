module FubuRake
  class NUnit
    def self.create_task(tasks, options)
	  nunitTask = nil
	  
	  tests = Array.new
	  
	  if options[:unit_test_projects].any?
		tests = options[:unit_test_projects]
	  elsif options[:unit_test_list_file] != nil and File::exists?(options[:unit_test_list_file])
		file = options[:unit_test_list_file]
		
		tests = NUnitRunner.readFromFile(file)
	  
	  else
	    # just find testing projects
		Dir.glob('**/*.{Testing,Tests}.csproj').each do |f|
		   test = File.basename(f, ".csproj")
		   tests.push test
		end
		
	  end
	  
	  if !tests.empty?
		nunitTask = Rake::Task.define_task :unit_test do
		  runner = NUnitRunner.new options
		  runner.executeTests tests
		end
	  
		nunitTask.enhance [:compile]
		nunitTask.add_description "Runs unit tests for " + tests.join(', ')
	  end

	  if tasks.integration_test != nil
	    integrationTask = Rake::Task.define_task :integration_test do
		  runner = NUnitRunner.new options
		  runner.executeTests tasks.integration_test
		end
		
		integrationTask.enhance [:compile]
		integrationTask.add_description "integration tests: #{tasks.integration_test.join(', ')}"
	  end
	end
  end
  
  
  
  class NUnitRunner
	include FileTest

	def initialize(paths)
		@sourceDir = paths.fetch(:source, 'src')
		@resultsDir = paths.fetch(:results, 'results')
		@compilePlatform = paths.fetch(:platform, '')
		@compileTarget = paths.fetch(:compilemode, 'debug')
		@clrversion = paths.fetch(:clrversion,  'v4.0.30319')
		@nunitExe = Nuget.tool("NUnit", "nunit-console#{(@compilePlatform.empty? ? '' : "-#{@compilePlatform}")}.exe") + Platform.switch("nothread")
	end
	
	def executeTests(assemblies)
		Dir.mkdir @resultsDir unless exists?(@resultsDir)
		
		assemblies.each do |assem|
			file = File.expand_path("#{@sourceDir}/#{assem}/bin/#{@compilePlatform.empty? ? '' : @compilePlatform + '/'}#{@compileTarget}/#{assem}.dll")
      puts "The platform is #{@compilePlatform}"
			sh Platform.runtime("#{@nunitExe} -noshadow -xml=#{@resultsDir}/#{assem}-TestResults.xml \"#{file}\"", @clrversion)
		end
	end
	
	def self.readFromFile(file)
	  tests = Array.new

	  file = File.new(file, "r")
	  assemblies = file.readlines()
	  assemblies.each do |a|
		test = a.gsub("\r\n", "").gsub("\n", "")
		tests.push(test)
	  end
	  file.close
	  
	  return tests
	end
	
	def executeTestsInFile(file)
	  if !File.exist?(file)
		throw "File #{file} does not exist"
	  end
	  
	  tests = readFromFile(file)
	  
	  if (!tests.empty?)
	    executeTests tests
	  end
	end
  end
  
  
end



