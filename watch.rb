require 'digest'


class FileVersion
	attr_accessor :path, :hash

	def initialize(path, hash)
		@path = path 
		@hash = hash
	end

	def to_s
		"#{@path} #{@hash}"
	end
end

def get_files(regexes)
	[] if regexes == nil || regexes.empty?
	regexes.collect {|regex| Dir.glob(regex)}.flatten.compact
end

def get_olds(file)
	return [] if File.size?(file) == nil

	File.foreach(file).collect { |line| 
		space_index = line.rindex(' ')
		FileVersion.new(line[0, space_index], line[space_index + 1, line.size - 1])
	}
end

def get_news(files)
	files.collect { |file|
		FileVersion.new(file, Digest::MD5.file(file).hexdigest)
	}	
end

def persist_file_hash(output, files)
	File.open(output, 'w') do |of|
		files.each do |file|
			of.write(file.to_s + "\n")
		end
	end
end

def changed 
	$build.changed false
end

def join_instruction_text(fvs)
	fvs.collect{|n| n.path}.join(' ')
end

class Build
	# Gets all files changed since last run of changed.
	def changed(add = true)
		files = get_files($build.config.watching)

		olds = get_olds($build.config.file_hash_file)
		news = get_news(files)

		persist_file_hash($build.config.file_hash_file, news) # save the current version before we screw with the list of ones.

		changeds = []

		news.each do |n| # O(N^2)
			oindex = olds.index {|o| o.path == n.path}
			if oindex == nil || olds[oindex].hash.strip != n.hash.strip
				changeds << n
			end
		end

		@instructions << BuildInstruction.new(16, join_instruction_text(changeds)) unless !add # the input files have spaces between them
		changeds # return what was actually changed.
	end

	def watch(what)
		@config.watching.push(what)
	end

	def watch_recursive(what)
		watch("./**/" + what)
	end

	def watch_only(what)
		@config.watching.clear
		watch what
	end

	def objects(add = true)
		objs = get_news(Dir.glob(config.obj_dir + "/*." + config.obj_file_ext))
		@instructions << BuildInstruction.new(16, join_instruction_text(objs)) unless !add # the input files have spaces between them
		objs
	end
end