require 'net/http'
require 'uri'

def is_uri?(uri)
  if uri =~ URI::ABS_URI
    true
  else
    false
  end
end

def fetch(uri_str, limit = 10)
  raise ArgumentError, 'HTTP redirect too deep - fetching halted' if limit == 0
  
  uri = URI.parse(is_uri?(uri_str)?uri_str:URI.escape(uri_str))
  
  http = Net::HTTP.start(uri.host)
  begin
    response = http.request_head(uri.request_uri, {'Accept' => 'application/rdf+xml, text/ntriples;q=0.5'})
  rescue => error
    puts "Couldn't fetch #{uri}"
  else
    puts "#{response.code} #{response.msg}: #{uri}"
    case response
    when Net::HTTPRedirection
      fetch(response['location'], limit - 1)
    else # => either if response is HTTPOK or anything else
      case response.content_type
      when 'application/rdf+xml', 'text/ntriples'
        http.finish
        http = Net::HTTP.start(uri.host)
        response = http.get(uri.request_uri, {'Accept' => 'application/rdf+xml, text/ntriples;q=0.5'})
      else
        response
      end
    end
  ensure
    http.finish if http.started?
  end
end