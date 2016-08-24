require 'socket'
require 'yaml'
require 'pry'

options = YAML.load_file('midepapai.yml')
addr = options["address"] || "localhost"
port = options["port"] || "2000"
root_files = options["location"] || "./"

papai = TCPServer.new(addr, port)

def handle_request_headers headers
  request_headers = {}
  headers.each do |h|
    type, content = h.split(":")
    request_headers[type.strip] = content.strip
  end
  return request_headers
end

def get_mime_type filename
  case File.extname(filename)
  when ".jpg", ".jpeg"
    mime_type = "image/jpeg"
  when ".gif"
    mime_type = "image/gif"
  when ".png"
    mime_type = "image/png"
  when ".html", ".htm"
    mime_type = "text/html"
  else
    mime_text = "Application/Octet-Stream"
  end
end

def handle_response_headers filename
  headers = []
  headers << "http/1.1 200 ok"
  headers << "server: midepapai"
  headers << "content-type: #{get_mime_type(filename)};"
  headers << "content-length: #{File.open(filename, 'r').size}"
  headers << "\r\n"
  return headers.join("\r\n")
end

def read_file file
  File.open(file, 'r') do |file|
    until file.eof?
      yield file.read(1024)
    end
  end
end

loop {
  Thread.start(papai.accept) do |mide|
    headers = []
    while header = mide.gets and header !~ /^\s*$/
      headers << header.chomp
    end
    puts headers
    # Pega a primeira linha que não segue o mesmo padrão dos outros
    file_requested = headers.shift.gsub(/GET\ \//, '').gsub(/\ HTTP.*/, '')
    handle_request_headers(headers)
    
    filename = file_requested.chomp
    if filename == ""
      filename = "index.html"
    end
    begin
      displayfile = File.open("#{root_files}#{filename}", 'r')
      header_resp = handle_response_headers("#{root_files}#{filename}")
      mide.print header_resp
      read_file("#{root_files}#{filename}") do |data|
        mide.print data
      end
    rescue Errno::ENOENT
      mide.print "File not found"
    end
    mide.close
  end
}
