module FubuRake
  class AssemblyBottle
	def initialize(project)
		@project = project
	end
	
	def create(options)
	  cleaned_name = @project.gsub('.', '_').downcase

	  name = "bottle_#{cleaned_name}"
	  task = Rake::Task.define_task name do
		sh "bottles assembly-pak #{options[:source]}/#{@project} -p #{@project}.csproj"

	  end
		
	  task.add_description "Assembly bottle packing for #{@project}"
	  Rake::Task[:compile].enhance [name]
	end
  end
end