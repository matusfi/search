require 'sinatra'
require "./helpers.rb"

get '/' do
  erb :index
end

get '/search' do
  unless params[:q].nil? || params[:q].empty?
    puts "Query: #{params[:q]}"
    
    if is_uri?(params[:q])
      uri = params[:q]
    else
      #                                                  ' ' -> '_'         '(hi)' -> '%28hi%29'
      uri = "http://dbpedia.org/resource/" + params[:q].gsub(/\s/,'_').gsub(/\((.*)\)/,'%28\1%29')
    end
    
    response = fetch uri
    if response.class == Net::HTTPOK && !response.body.nil?
      @result = prepare(parse(response), 3)
    end
  end
  
  puts "--------------------------------------------------"
  puts " Done preparing --> starting to fill the template"
  puts "--------------------------------------------------"

  erb :render, :layout => false
end