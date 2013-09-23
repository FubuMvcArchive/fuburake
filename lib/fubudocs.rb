namespace :docs do
	desc "Runs a documentation project hosted in FubuWorld"
	task :run do
		sh "fubudocs run -o"
	end
	
	desc "Runs the documentation projects in this solution in a 'watched' mode in Firefox"
	task :run_firefox do
		sh "fubudocs run --watched --browser Firefox"
	end
	
	desc "Runs the documentation projects in this solution in a 'watched' mode in Firefox"
	task :run_chrome do
		sh "fubudocs run --watched --browser Chrome"
	end

	desc "'Bottles' up a single project in the solution with 'Docs' in its name"
	task :bottle do
		sh "fubudocs bottle"
	end

	desc "Gathers up code snippets from the solution into the Docs project"
	task :snippets do
		sh "fubudocs snippets"
	end
end



  class FubuDocs
    attr_accessor :prefix, :branch, :export_dir
  
    def initialize(options)
		# :host, :include, :nested, :dump
		@branch = options.fetch(:branch, 'gh-pages')
		@repository = options[:repository]
		@prefix = options.fetch(:prefix, 'docs')
		@export_dir = options.fetch(:dir, 'fubudocs-export')
		@options = options
	end
	
	def export
	  cmd = "fubudocs export #{@export_dir}"
	  if (@options[:host] != nil)
		cmd += " --host #{@options[:host]}"
	  end

	  if (@options[:include] != nil)
		cmd += " -i #{@options[:include]}"
	  end
	  
	  if (@options[:nested] == true)
		cmd += " -m GhPagesChildFolder"
	  elsif (@options[:dump] == true)
	    cmd += " -m HtmlDump"
	  else
		cmd += ' -m GhPagesRooted'
	  end
	  
	  sh cmd
	end
	
	def clean
	  cleanDirectory @export_dir
	  Dir.delete @export_dir unless !Dir.exists?(@export_dir)
	end
	
	def create_branch
	  sh "ripple gitignore #{@export_dir}"
		  
	  sh "git clone #{@repository} #{@export_dir}"
		  
	  Dir.chdir @export_dir
		  
	  sh "git checkout --orphan #{@branch}"
	  sh "git rm -rf ."
	  
	  writeNoJekyll
	  
	  sh "git add ."
	  sh 'git commit -a -m "initial clean slate"'
	  sh 'git push origin #{@branch}'
		  
	  Dir.chdir '..'
	end
	
	def writeNoJekyll
	  output = File.new( ".nojekyll", "w+" )
	  output << "Just a marker"
      output.close
	end
	
	def fetch_existing
	  Dir.mkdir @export_dir
		  
	  # fetch the gh-pages branch from the server
	  Dir.chdir @export_dir
	  sh 'git init'
	  sh "git remote add -t #{@branch} -f origin #{@repository}"
	  sh "git checkout #{@branch}"	
	  
	  # clean the existing content
	  sleep 0.5 # let the file system try to relax its locks
	  content_files = FileList['*.*'].exclude('.nojekyll').exclude('CNAME')
	  content_files.each do |f|
	    FileUtils.rm_r f
	  end
		  
	  # do the actual export
	  Dir.chdir '..'
	end
	
	def commit_new
	  # commit and push the generated docs
	  Dir.chdir @export_dir
	  
	  if !File.exists?('.nojekyll')
		writeNoJekyll
	  end
	  
	  sh "git add ."
	  sh 'git commit -a -m "Doc generation version ' + @options[:version] + '"' do |ok, res|
		if ok
		  sh "git push origin #{@branch}"
		  puts "Documentation generation and push to #{@repository}/#{@branch} is successful"
		else
		  puts "commit failed, might be because there are no differences in the content"
		end
	  end

	  Dir.chdir '..'
	end
	
	def export_tasks
		initTask = Rake::Task.define_task "#{@prefix}:init_branch" do
		  clean
		  create_branch
		end
		
		initTask.add_description "Initializes the #{@branch} branch in git repository #{@repository}"
		
		exportTaskName = "#{@prefix}:export"
		exportTask = Rake::Task.define_task exportTaskName do
		  clean
          fetch_existing
		  export
		  commit_new
		end
		exportTask.add_description "Export the generated documentation to #{@repository}/#{@branch}"
		#exportTask.enhance [:compile]
		
		
		return exportTaskName
	end
	
	def dump_task
	  dumpTask = Rake::Task.define_task "#{@prefix}:dump" do
	    clean
		@options[:dump] = true
		export
	  end
	  dumpTask.add_description "Export the generated documentation to #{@export_dir} for local usage"
	end
  end
  
