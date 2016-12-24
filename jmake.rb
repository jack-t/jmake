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
		if what.start_with?(config.obj_dir + "/") # '/' is safe on all platform in Ruby.
			what = change_ext(what, @config.obj_file_ext)
		end
		@instructions << BuildInstruction.new(14, "-o " + what)
	end

	def into(what)
		named(what) # alias
	end

end