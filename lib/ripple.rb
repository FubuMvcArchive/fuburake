# vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
module FubuRake
	class Ripple
		def self.create(tasks, options)
			if !tasks.ripple_enabled
				return
			end

			tasks.clean << options[:nuget_publish_folder]

			restoreTask = Rake::Task.define_task 'ripple:restore' do
				puts 'Restoring all the nuget package files'
				sh 'ripple restore'
			end
			restoreTask.add_description "Restores nuget package files and updates all floating nugets"

			updateTask = Rake::Task.define_task 'ripple:update' do
				puts 'Cleaning out existing packages out of paranoia'
				sh 'ripple clean'

				puts 'Updating all the nuget package files'
				sh 'ripple update'
			end
			updateTask.add_description	"Updates nuget package files to the latest"


			historyTask = Rake::Task.define_task 'ripple:history' do
				sh 'ripple history'
			end
			historyTask.add_description "creates a history file for nuget dependencies"

			packageTask = Rake::Task.define_task 'ripple:package' do
				sh "ripple local-nuget --version #{options[:build_number]} --destination #{options[:nuget_publish_folder]}"
			end
			packageTask.add_description "packages the nuget files from the nuspec files in packaging/nuget and publishes to /#{options[:nuget_publish_folder]}"
			packageTask.enhance [:compile]
		
			if !options[:nuget_publish_url].nil?
				cmd = "ripple batch-publish #{options[:nuget_publish_folder]} --server #{options[:nuget_publish_url]}"
				if !options[:nuget_api_key].nil?
					cmd += " --api-key " + options[:nuget_api_key]
				end
			
				publishTask = Rake::Task.define_task 'ripple:publish' do
					sh cmd
				end
				publishTask.add_description "publishes the built nupkg files"
				publishTask.enhance ['ripple:package']
				
				add_dependency :ci, 'ripple:publish'
			end
		end
	end
end

