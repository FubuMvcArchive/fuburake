# vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
module Platform

	def self.is_nix
		!RUBY_PLATFORM.match("linux|darwin").nil?
	end

	def self.runtime(cmd, runtime)
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
