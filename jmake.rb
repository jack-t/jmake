load 'config.rb'
load 'watch.rb'

class BuildInstruction
	attr_accessor :order, :text
	def initialize(order, text)
		@order = order
		@text = text
	end

	def empty?
		@text.empty?
	end
end

class Build
	attr_accessor :instructions, :config

	def initialize()
		@instructions = []
		@config = Configuration.new
	end
end
$build = Build.new

def build(&instructions)

	$build.instructions.concat $build.config.build_instructions
	$build.instance_eval(&instructions) # 
	$build.instructions.sort_by! { |x| x.order }

	command = $build.instructions.collect{|x| x.text}.join(" ")
	system(command)
end

# build just a particular file (probably given to you by #each)
def build_just(file, &instructions)
	$build.instructions << BuildInstruction.new(16, file.to_s)
	build(&instructions)
end

def each(files)
	files.each do |file|
		before = $build.instructions.dup
		yield(file.path)
		# Don't re-compile each successive file; get rid of all the instructions except for the 
		$build.instructions.clear
		$build.instructions = before.dup
	end
end

def change_ext(str, ext)
	idot = str.rindex(".")
	if idot == nil
		str + "." + ext
	else
		str.slice(0, idot) + "." + ext
	end
end

class Build
	def as(what)
		case what.to_s
		when "obj"
			@instructions << BuildInstruction.new(1, "-c")
		when "exe"
			# doesn't do anything; just makes things more explicit if that's what you like to do.
		end
	end

	def named(what)
		if what.to_s.start_with?(config.obj_dir + "/") # '/' is safe on all platforms in Ruby.
			what = change_ext(what.to_s, @config.obj_file_ext)
		end
		@instructions << BuildInstruction.new(14, "-o " + what.to_s)
	end

	def into(what)
		named(what) # alias
	end

	def with_include_directory(what)
		@instructions << BuildInstruction.new(8, "-I" + what.to_s)
	end

	def with_library(lib)
		@instructions << BuildInstruction.new(17, "-l" + lib.to_s) # 17 because libraries must come after the compilation units that require them
	end

	def with_library_dir(directory)
		@instructions << BuildInstruction.new(15, "-L" + directory.to_s) 
	end

	def with_option(option)
		@instructions << BuildInstruction.new(VALUE, "-" + option)
	end

end