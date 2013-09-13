namespace :docs do
	desc "Tries to run a documentation project hosted in FubuWorld"
	task :run do
		sh "fubudocs run -o"
	end
	
	desc "Tries to run the documentation projects in this solution in a 'watched' mode in Firefox"
	task :run_firefox do
		sh "fubudocs run --watched --browser Firefox"
	end
	
	desc "Tries to run the documentation projects in this solution in a 'watched' mode in Firefox"
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


module FubuRake
  class FubuDocsGitExport
    
	def self.create_tasks(options)
		# :repo, :branch
		branch = options.fetch(:branch, 'gh-pages')
		repository = options[:repository]
		prefix = options.fetch(:prefix, 'docs')
		
		initTask = Rake::Task.define_task "#{prefix}:init_branch" do
		  cleanDirectory 'fubudocs-export'
		  Dir.delete 'fubudocs-export'

		  sh "ripple gitignore fubudocs-export"
		  
		  sh "git clone #{repository} fubudocs-export"
		  
		  Dir.chdir 'fubudocs-export'
		  
		  sh "git checkout --orphan #{branch}"
		  sh "git rm -rf ."
		  
		  output = File.new( ".nojekyll", "w+" )
		  output << "Just a marker"
          output.close
		  
		  sh "git add ."
		  sh 'git commit -a -m "initial clean slate"'
		  sh 'git push origin gh-pages'
		  
		  Dir.chdir '..'
		end
		
		initTask.add_description "Initializes the #{branch} branch in git repository #{repository}"
		
		exportTaskName = "#{prefix}:export"
		exportTask = Rake::Task.define_task exportTaskName do
		  # seed the directory
		  cleanDirectory 'fubudocs-export'
		  Dir.delete 'fubudocs-export'
		  Dir.mkdir 'fubudocs-export'
		  
		  # fetch the gh-pages branch from the server
		  Dir.chdir 'fubudocs-export'
		  sh 'git init'
		  sh "git remote add -t #{branch} -f origin #{repository}"
		  sh "git checkout #{branch}"
		  
		  
		  
		  # clean the existing content
		  sleep 0.5 # let the file system try to relax its locks
		  content_files = FileList['*.*'].exclude('.nojekyll')
		  content_files.each do |f|
		    FileUtils.rm_r f
		  end
		  
		  # do the actual export
		  Dir.chdir '..'
		  cmd = "fubudocs export fubudocs-export"
		  if (options[:host] != nil)
		    cmd += " --host #{options[:host]}"
		  end

		  if (options[:include] != nil)
		    cmd += " -i #{options[:include]}"
		  end
		  
		  # TODO -- will need to filter the doc projects
		  sh cmd
		  
		  
		  # commit and push the generated docs
		  Dir.chdir 'fubudocs-export'
		  
		  sh "git add ."
		  sh 'git commit -a -m "Doc generation version ' + options[:version] + '"' do |ok, res|
			if ok
		      sh "git push origin #{branch}"
		      puts "Documentation generation and push to #{repository}/#{branch} is successful"
			else
			  puts "commit failed, might be because there are no differences in the content"
			end
		  end
		  

		  
		  Dir.chdir '..'
		end
		exportTask.add_description "Export the generated documentation to #{repository}/#{branch}"
		#exportTask.enhance [:compile]
		
		
		return exportTaskName
	end
  end
  
end