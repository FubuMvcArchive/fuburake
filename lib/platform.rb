# vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
module Platform

	def self.is_nix
		!RUBY_PLATFORM.match("linux|darwin").nil?
	end

	def self.is_linux
		!RUBY_PLATFORM.match("linux").nil?
	end

	def self.is_darwin
		!RUBY_PLATFORM.match("darwin").nil?
	end

	def self.start(path)
		command = "start #{path}"
		if self.is_linux
			command = "xdg-open #{path}"
		elsif self.is_darwin
			command = "open #{path}"
		end
		sh command
	end

	def self.runtime(cmd, runtime='v4.0.30319')
		command = cmd
		if self.is_nix
			command = "mono --runtime=#{runtime} #{cmd}"
		end
		command
	end

	def self.switch(arg)
		sw = self.is_nix ? " -" : " /"
		sw + arg
	end
end
