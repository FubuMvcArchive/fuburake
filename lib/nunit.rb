module FubuRake
  class NUnit
    def self.create_task(tasks, options)
	  nunitTask = nil
	  if options[:unit_test_projects].any?
		nunitTask = Rake::Task.define_task :unit_test do
		  runner = NUnitRunner.new options
		  runner.executeTests options[:unit_test_projects]
		end
	  elsif options[:unit_test_list_file] != nil and File::exists?(options[:unit_test_list_file])
		file = options[:unit_test_list_file]
	  
		nunitTask = Rake::Task.define_task :unit_test do
		  runner = NUnitRunner.new options
		  runner.executeTestsInFile file
		end
	  end
	  
	  if nunitTask != nil
		nunitTask.enhance [:compile]
		nunitTask.add_description "Runs unit tests"
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
end

class NUnitRunner
	include FileTest

	def initialize(paths)
		@sourceDir = paths.fetch(:source, 'src')
		@resultsDir = paths.fetch(:results, 'results')
		@compilePlatform = paths.fetch(:platform, 'x86')
		@compileTarget = paths.fetch(:compilemode, 'debug')
		@clrversion = paths.fetch(:clrversion,  'v4.0.30319')
		@nunitExe = Nuget.tool("NUnit", "nunit-console#{(@compilePlatform.empty? ? '' : "-#{@compilePlatform}")}.exe") + Platform.switch("nothread")
	end
	
	def executeTests(assemblies)
		Dir.mkdir @resultsDir unless exists?(@resultsDir)
		
		assemblies.each do |assem|
			file = File.expand_path("#{@sourceDir}/#{assem}/bin/#{@compileTarget}/#{assem}.dll")
			sh Platform.runtime("#{@nunitExe} -xml=#{@resultsDir}/#{assem}-TestResults.xml \"#{file}\"", @clrversion)
		end
	end
	
	def executeTestsInFile(file)
	  if !File.exist?(file)
		throw "File #{file} does not exist"
	  end
	  
	  tests = Array.new

	  file = File.new(file, "r")
	  assemblies = file.readlines()
	  assemblies.each do |a|
		test = a.gsub("\r\n", "").gsub("\n", "")
		tests.push(test)
	  end
	  file.close
	  
	  if (!tests.empty?)
	    executeTests tests
	  end
	end
end