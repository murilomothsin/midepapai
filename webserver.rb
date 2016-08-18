require 'socket'
require 'yaml'

options = YAML.load_file('midepapai.yml')
addr = options[:address] || "localhost"
port = options[:port] || "2000"

root_files = options[:location] || "./"

papai = TCPServer.new(addr, port)

loop {
	Thread.start(papai.accept) do |mide|
		mide.print "HTTP/1.1 200/OK\r\nContent-type:text/html\r\n\r\n"
		request = mide.gets
		puts request
		trimmedrequest = request.gsub(/GET\ \//, '').gsub(/\ HTTP.*/, '')
		filename = trimmedrequest.chomp
		if filename == ""
			filename = "index.html"
		end
		begin
			displayfile = File.open("#{root_files}#{filename}", 'r')
			content = displayfile.read()
			mide.print content
		rescue Errno::ENOENT
			mide.print "File not found"
		end
		mide.close
	end
}
