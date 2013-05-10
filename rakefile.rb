load 'lib/fuburake.rb'

FubuRake::Solution.new do |sln|
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