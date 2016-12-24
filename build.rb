load 'jmake.rb'

system("mkdir obj")

each changed do |file|
	build_just file do
		as :obj
		named :"obj/#{file}"
	end
end

build do
	objects
	as :exe
	named :jmake
end 
