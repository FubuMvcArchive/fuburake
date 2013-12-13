# vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
include FileUtils
include FileTest

require_relative 'nunit'
require_relative 'msbuild'
require_relative 'nuget'
require_relative 'platform'
require_relative 'ripple'
require_relative 'assembly_info'
require_relative 'bottles'
require_relative 'fubudocs'

if File.exists?("VERSION.txt")
	load "VERSION.txt"
elsif ENV["BUILD_VERSION"] != nil
	BUILD_VERSION = ENV["BUILD_VERSION"]
else
	BUILD_VERSION = "0.0.1"
end

module FubuRake
	class SolutionTasks
	attr_accessor :clean, 
		:compile, 
		:assembly_info,
		:ripple_enabled, 
		:fubudocs_enabled, 
		:options, 
		:defaults,
		:ci_steps,
		:precompile,
		:integration_test,
		:compilations,
		:bottles,
		:bottles_enabled,
		:doc_exports
		
	def initialize
		@options = {}
		@bottles = []
		@bottles_enabled = true
	
		solutions = Dir.glob('**/*.sln')
		if solutions.count == 1
			solutionfile = solutions[0]

			@compile = {:solutionfile => solutionfile}
		end
	end	
		
	def compile_step(name, solution)
		@compilations ||= []
	
		@compilations << CompileTarget.new(name, solution)
	end
	
	def assembly_bottle(project)
		@bottles ||= []
	
		@bottles << FubuRake::AssemblyBottle.new(project)
	end
	
	def export_docs(options)
		@doc_exports ||= []
		
		@doc_exports << options
	end
	end
	
	class Solution
		attr_accessor :options, :compilemode, :build_number
	
		def initialize(&block)
			tasks = SolutionTasks.new
			block.call(tasks)

			@defaultTask = create_task(:default, "**Default**, compiles and runs tests")
			@ciTask = create_task(:ci,	"Target used for the CI server")
			@ciTask.enhance [:default]
		
			options = tasks.options
			options ||= {}
		
			tc_build_number = ENV["BUILD_NUMBER"]
			build_revision = tc_build_number || Time.new.strftime('5%H%M')
			asm_version = BUILD_VERSION + ".0"
			@build_number = "#{BUILD_VERSION}.#{build_revision}"

			# SAMPLE: fuburake-options
			@options = {
				:compilemode => ENV['config'].nil? ? "Debug" : ENV['config'],
				:clrversion => 'v4.0.30319',
				:platform => ENV['platform'].nil? ? "" : ENV['platform'],
				:unit_test_list_file => 'TESTS.txt',
				:unit_test_projects => [],
				:build_number => @build_number,
				:asm_version => asm_version,
				:tc_build_number => tc_build_number,
				:build_revision => build_revision,
				:source => 'src'}.merge(options)
			# ENDSAMPLE
		
			@compilemode = @options[:compilemode]
		
			tasks.clean ||= []
			tasks.defaults ||= []
			tasks.ci_steps ||= []
			tasks.precompile ||= []
			tasks.doc_exports ||= []

			enable_docs tasks
			FubuRake::AssemblyInfo.create tasks, @options
			FubuRake::Ripple.create tasks, @options
			make_clean tasks
			FubuRake::MSBuild.create_task tasks, @options
			FubuRake::NUnit.create_task tasks, @options

			add_dependency :compile, [:clean, :version, 'ripple:restore', 'docs:bottle']

			Rake::Task[:compile].enhance(tasks.precompile)
			add_dependency :unit_test, :compile
			add_dependency :default, [:compile, :unit_test]
			add_dependency :default, :unit_test
			Rake::Task[:default].enhance tasks.defaults
			Rake::Task[:ci].enhance tasks.ci_steps
			add_dependency :ci, tasks.ci_steps
			add_dependency :ci, ["ripple:history", "ripple:package"]

			tasks.compilations ||= []
			tasks.compilations.each do |c|
				c.create @options
			end
				
			if tasks.bottles.empty? && tasks.bottles_enabled
				Dir.glob('**/.package-manifest').each do |f|
					dir = File.dirname(f)
					project = dir.split('/').last
					if project.index('.Docs') == nil
						proj_file = "#{dir}/#{project}.csproj"
						if File.exists?(proj_file)
							tasks.assembly_bottle File.basename(project)
						end
					end
				end
			end
		
			if !tasks.bottles.empty?
				tasks.bottles.each do |c|
					c.create @options
				end
			end

			tasks.doc_exports.each do |opts|
				opts[:version] = @build_number
		
				docs = FubuDocs.new(opts)

				doc_task_name = docs.export_tasks
				if opts[:include_in_ci]
					add_dependency :ci, doc_task_name
				end
			end
	
		end
	
		def add_dependency(from, to)
			if to.kind_of?(Array)
				to.each do |dep|
					add_dependency from, dep
				end
			end
	
			if !Rake::Task.task_defined?(from)
				return
			end
		
			if !Rake::Task.task_defined?(to)
				return
			end 
		
			Rake::Task[from].enhance [to]
		end
	
		def create_task(name, description)
			task = Rake::Task.define_task name do
		
			end
			task.add_description description
		
			return task
		end

		def make_clean(tasks)
			if tasks.clean.any?
				@cleanTask = Rake::Task.define_task :clean do
				tasks.clean.each do |dir|
					cleanDirectory dir
				end
			end
		
			@cleanTask.add_description "Prepares the working directory for a new build"
			end
		end


		def enable_docs(tasks)
			if tasks.fubudocs_enabled
				if Platform.is_nix
					Dir.glob('**/*.Docs.csproj').each do |f|
						tasks.assembly_bottle File.basename(f, ".csproj")
					end
				else
					require_relative 'fubudocs'
				end
			end
		end
	
		def dump_html(options)
			options[:version] = @build_number
			docs = FubuDocs.new(options)
			docs.dump_task
		end
	end
	
	class MvcApp
		def initialize(options)
			cleaned_name = options[:name].gsub('.', '_').downcase
			run_args = "--directory #{options[:directory]}"
		
			if options.has_key?(:application)
				run_args += " --application #{options[:application]}
			end
		
			if options.has_key?(:build)
				run_args += " --build #{options[:build]}"
			end

			task = Rake::Task.define_task "#{cleaned_name}:alias" do
				sh "bottles alias #{cleaned_name} #{options[:directory]}"
			end
			task.add_description "Add the alias for #{options[:directory]}"
			Rake::Task[:default].enhance ["#{cleaned_name}:alias"]
		
		
			to_task "#{cleaned_name}:restart", "restart #{cleaned_name}", "touch the web.config file to force ASP.Net hosting to recycle"
			to_task "#{cleaned_name}:run", "run #{run_args} --open", "run the application with Katana hosting"
			to_task "#{cleaned_name}:firefox", "run #{run_args} --browser Firefox --watched", "run the application with Katana hosting and 'watch' the application w/ Firefox"
			to_task "#{cleaned_name}:chrome", "run #{run_args} --browser Chrome --watched", "run the application with Katana hosting and 'watch' the application w/ Chrome"
		
		end
	
		def to_task(name, args, description)
			task = Rake::Task.define_task name do
				sh "fubu #{args}"
			end
		
			task.add_description description
			return task
		end
	end
	
	
	class BottleServices
		def initialize(options)
			@directory = options[:dir]
			@prefix = options.fetch(:prefix, 'service')
			@command = File.join(@directory, 'BottleServiceRunner.exe')
		
			consoleTask = Rake::Task.define_task "#{@prefix}:console" do
				sh "#{Platform.start(Platform.runtime(@command))}"
			end
			consoleTask.add_description "Run service in console at #{@directory}"
		
			to_task 'install', to_install_args(options), "Install the service locally"
			to_task 'start', to_start_stop_args('start', options), "Start the service locally"
			to_task 'stop', to_start_stop_args('stop', options), "Stop the service locally"
			to_task 'uninstall', to_start_stop_args('uninstall', options), "Stop the service locally"
		
			cleanTask = Rake::Task.define_task "#{@prefix}:clean" do
				dir = File.join(@directory, 'fubu-content')
				cleanDirectory dir
			end
			cleanTask.add_description "Cleans out any exploded bottle content at fubu-content"
		end
		
		def to_start_stop_args(verb, options)
			args = "#{verb}"
		
			if (options[:name] != nil)
				args += " -servicename:#{options[:name]}"
			end
		
			if (options[:instance] != nil)
				args += " -i:#{options[:instance]}"
			end
		
			return args
		end
		
		def to_install_args(options)
			args = "install";
		
			if (options[:name] != nil)
				args += " -servicename:#{options[:name]}"
			end
		
			if (options[:instance] != nil)
				args += " -i:#{options[:instance]}"
			end

			if (options[:user] != nil)
				args += " -u:#{options[:user]}"
			end
	
			if (options[:password] != nil)
				args += " -p:#{options[:password]}"
			end

			if (options[:autostart] == true)
				args += " --autostart"
			end
		
			if (options[:manual] == true)
				args += " --manual"
			end
	
			if (options[:disabled] == true)
				args += " --disabled"
			end

			if (options[:delayed] == true)
				args += " --delayed"
			end
		
			if (options[:local_service] == true)
				args += " --localservice"
			end
		
			if (options[:network_service] == true)
				args += " --networkservice"
			end
		
			if (options[:interactive] == true)
				args += " --interactive"
			end
		
			if (options[:description] != nil)
				args += ' -d:"' + options[:description] + "'"
			end
		
			return args
		end
		
		def to_task(name, args, description)
			task = Rake::Task.define_task "#{@prefix}:#{name}" do
				sh "#{@command} #{args}"
			end
		
			task.add_description description
			return task
		end
	end
		
	
	class Storyteller
		def initialize(options)
			# :path
			# :compilemode -- take it from @solution.compiletarget
			# :results
			# :workspace
			# :profile
			# :title
			# :source
			# :prefix
			# :st_path
			# :specs
		
			@directory = options[:dir]
			@prefix = options.fetch(:prefix, 'st')
			@src = options.fetch(:source, 'src')
			@results = options.fetch(:results, 'results.htm')
			@st_path = options.fetch(:st_path, "#{@src}/packages/Storyteller2/tools")
			@title = options.fetch(:title, 'Storyteller Specs')
			@specs = options.fetch(:specs, 'specs')
			@suites = options.fetch(:suites, [])

			to_task 'run', 'ST.exe', "run #{to_args(options, @results)}", "Run the Storyteller tests for #{@directory}"
			to_task 'specs', 'ST.exe', "specs #{to_args(options, @specs)} --title \"#{@title}\"", "dump the specs for Storyteller tests at #{@directory}"
			
			@suites.each do |s|
				to_task "run:#{s.downcase}", 'ST.exe', "run #{to_args(options, @results)} -w #{s}", "Run the Storyteller tests for suite #{s}"
			end

			if !Platform.is_nix
				# StoryTellerUI.exe is a WPF application which is 
				# not supported on nix and therefore setting up the task
				# is pointless.
				openTask = Rake::Task.define_task "#{@prefix}:open" do
					tool = 'StoryTellerUI.exe'
					cmd = Platform.runtime("#{File.join(@st_path, tool)}") + " #{to_args(options, @results)}"
					puts "Opening the Storyteller UI to #{@directory}"
					sh cmd
				end
				openTask.add_description "Open the Storyteller UI for tests at #{@directory}"
				openTask.enhance [:compile]
			end
		end
		
		
		def to_task(name, tool, args, description)
			task = Rake::Task.define_task "#{@prefix}:#{name}" do
				sh Platform.runtime("#{File.join(@st_path, tool)}") + " #{args}"
			end
		
			task.add_description description
			task.enhance [:compile]
		
			return task
		end
		
		def to_args(options, output)
			args = "#{options[:path]} #{output}"
		
			if (options[:compilemode] != nil)
				args += " --compile #{options[:compilemode]}"
			end
		
			if (options[:workspace] != nil)
				args += " --workspace #{options[:workspace]}"
			end
		
			if (options[:profile] != nil)
				args += " --profile #{options[:profile]}"
			end
		
			return args
		end
	end
end





def copyOutputFiles(fromDir, filePattern, outDir)
	Dir.glob(File.join(fromDir, filePattern)){|file|		
		copy(file, outDir) if File.file?(file)
	} 
end

def waitfor(&block)
	checks = 0
	until block.call || checks >10 
		sleep 0.5
		checks += 1
	end
	raise 'waitfor timeout expired' if checks > 10
end

def cleanDirectory(dir)
	if exists?(dir)
		puts 'Cleaning directory ' + dir
		FileUtils.rm_rf dir;
		waitfor { !exists?(dir) }
	end
	
	if dir == 'artifacts'
		Dir.mkdir 'artifacts'
	end
end

def cleanFile(file)
	File.delete file unless !File.exist?(file)
end

