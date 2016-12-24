class Configuration
	attr_accessor :watching, :obj_dir, :build_instructions, :file_hash_file, :obj_file_ext

	def initialize()
		@obj_dir = "obj"
		@file_hash_file = ".jmake" # where we store the old hashes
		@watching = ["*.cpp"]
		@build_instructions = [BuildInstruction.new(0, "g++")]
		@obj_file_ext = "o"
	end
end

