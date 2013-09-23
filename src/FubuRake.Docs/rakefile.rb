# SAMPLE: simple-rake
load 'lib/fuburake.rb'

solution = FubuRake::Solution.new do |sln|
	sln.compile = {
		:solutionfile => 'src/FubuRake.sln'
	}
				 
	sln.assembly_info = {
		:product_name => "FubuRake",
		:copyright => 'Copyright Some Year by Some Guy'
	}
	
	sln.ripple_enabled = true
	sln.fubudocs_enabled = true
end
# ENDSAMPLE

# SAMPLE: enable-ripple
solution = FubuRake::Solution.new do |sln|
	sln.ripple_enabled = true
end
# ENDSAMPLE

# SAMPLE: enable-fubudocs
solution = FubuRake::Solution.new do |sln|
	sln.fubudocs_enabled = true
end
# ENDSAMPLE


# SAMPLE: override-options
load 'lib/fuburake.rb'

solution = FubuRake::Solution.new do |sln|
	sln.options = {
		:compilemode => 'Custom',
		:unit_test_projects => ['Something.Tests']
	}
end
# ENDSAMPLE


# SAMPLE: using-options-later
@solution = FubuRake::Solution.new do |sln|
	# Configure your rake script here...
end

puts "The build number is #{@solution.options[:build_number]}"
# ENDSAMPLE

# SAMPLE: default-compile
solution = FubuRake::Solution.new do |sln|
	sln.compile = {
		:solutionfile => 'src/FubuRake.sln'
	}
end
# ENDSAMPLE

# SAMPLE: version
	sln.assembly_info = {
		:product_name => "FubuRake",
		:copyright => 'Copyright Some Year by Some Guy'
	}
# ENDSAMPLE



# SAMPLE: compile-step
@solution = FubuRake::Solution.new do |sln|
	sln.compile = {
		:solutionfile => 'src/Bottles.sln'
	}
				 
	sln.compile_step :compile_console, 'src/Bottles.Console/Bottles.Console.csproj'
	sln.compile_step :compile_bottle_project, 'bottles-staging/BottleProject.csproj'
end
# ENDSAMPLE

# SAMPLE: precompile
@solution = FubuRake::Solution.new do |sln|
	sln.compile = {
		:solutionfile => 'src/Bottles.sln'
	}

	sln.precompile = [:bottle_assembly_package]
end

desc "does the assembly bottling of the AssemblyPackage test project"
task :bottle_assembly_package => [:compile_bottle_project] do
  # do the bottling...
end
# ENDSAMPLE


# SAMPLE: clean-task
@solution = FubuRake::Solution.new do |sln|
	sln.clean = ['results', 'archive']
end
# ENDSAMPLE



# SAMPLE: explicit-tests
@solution = FubuRake::Solution.new do |sln|
	sln.options = {
		:unit_test_projects => ['Bottles.Tests']
	}
end
# ENDSAMPLE

# SAMPLE: integration-test
@solution = FubuRake::Solution.new do |sln|
	sln.integration_test = ['Bottles.IntegrationTesting']
end
# ENDSAMPLE


# SAMPLE: custom-tasks
@solution = FubuRake::Solution.new do |sln|
	sln.defaults = [:ilrepack, :integration_test]
	sln.ci_steps = [:ilrepack, :archive_gem]
end

task :ilrepack do
    #something here...
end
# ENDSAMPLE

# SAMPLE: explicit-bottle
@solution = FubuRake::Solution.new do |sln|
	# Other options
	
	sln.assembly_bottle 'FubuMVC.Diagnostics'
end
# ENDSAMPLE



# SAMPLE: disable-bottling
@solution = FubuRake::Solution.new do |sln|
	# Other options

	sln.bottles_enabled = false # need to do the zip bottling in tests, so don't do it here
end
# ENDSAMPLE


# SAMPLE: publishing
@solution = FubuRake::Solution.new do |sln|
  sln.export_docs({
    :repository => 'git@github.com:DarthFubuMVC/fuburake.git', 
    :prefix => 'docs',
    :branch => 'gh-pages',
    :include => 'FubuRake',
    :nested => true,
    :dump => true,
    :dir => 'fubudocs-export',
    :host => 'src/SomeFolder'
  })
end
# ENDSAMPLE

# SAMPLE: dump-html
@solution = FubuRake::Solution.new do |sln|

end

@solution.dump_html({
  :prefix => 'docs',
  :include => 'FubuRake',
  :dir => 'fubudocs-export',
  :host => 'src/SomeFolder'
  :nested => true,
  :dump => true
})
# ENDSAMPLE


# SAMPLE: bottle-services
@solution = FubuRake::Solution.new do |sln|

end

FubuRake::BottleServices.new({
  # Use this option to use a different prefix for the 
  # generated tasks
  :prefix => "service", 
  
  # This option needs to point at the directory of the build
  # products of the service project
  :dir => "src/DiagnosticsHarness/bin/#{@solution.compilemode}", 
  :name => 'ft-harness', 
  :instance => 'something',
  :user => 'user name',
  :password => 'password',
  :autostart => true,
  :manual => true,
  :disabled => true,
  :delayed => true,
  :local_service => true,
  :network_service => true,
  :interactive => true,
  :description => 'something'
  :manual => true
})
# ENDSAMPLE
