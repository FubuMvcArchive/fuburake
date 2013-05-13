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