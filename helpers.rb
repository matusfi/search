require 'rdf'
require 'rdf/ntriples'
require 'rdf/rdfxml'
include RDF
# --------------------
require './net.rb'
require './result.rb'

def parse(response)
  puts "Parsing..."
  results = []
  case response['content-type']
  when /^application\/rdf\+xml.*$/  # => should be a RDF/XML format
    RDF::RDFXML::Reader.new(response.body) do |reader|
      reader.each_statement do |statement|
        results.push(statement) if show?(statement.object)
      end
    end
  when /^text\/plain.*$/ # => should be NTriples format
    RDF::NTriples::Reader.new(response.body) do |reader|
      reader.each_statement do |statement|
        results.push(statement) if show?(statement.object)
      end
    end
  else
    nil
  end
  
  puts "Parsing done!"
  results
end

def prepare(results, limit = nil)
  unless results.empty?
    sort(results) # so the relevant statements would be first
    results = results.take(limit) if limit
    
    subjects = get_unique_subjects(results)
    predicates = get_unique_predicates(results)
    objects = get_unique_objects(results)
  
    puts "Subjects:   #{subjects.size} in #{subjects.class}"
    puts "Predicates: #{predicates.size} in #{predicates.class}"
    puts "Objects:    #{objects.size} in #{objects.class}"
  
    results.map do |result|
      Result.new(
        subjects[subjects.index{|x| x[:uri] == result.subject}],
        predicates[predicates.index{|x| x[:uri] == result.predicate}],
        objects[objects.index{|x| x[:uri] == result.object}])
    end
  end
end

def sort(results)
  puts "Sorting for: "
  [RDFS.comment].reverse.each do |predicate|
    puts "            #{predicate.to_s}"
    temp = []
    while i = results.index {|r| r.predicate == predicate}
      temp.push results[i]
      results.delete_at i
    end
    
    temp.each do |l|
      results.unshift l
    end
    
  end
  puts "Sorting done!"
end


def get_unique_subjects(results)
  puts "-----------"
  puts "unique SUBJECTS"
  r=results.uniq{|r| r.subject}.map do |r|
    l,c = resource_label_comment(r.subject.to_s)
    {:uri => r.subject, :label => l, :comment => c}
  end
  puts "Done!"
  puts "-----------"
  r
end

def get_unique_predicates(results)
  puts "unique PREDICATES"
  r=results.uniq{|r| r.predicate}.map do |r|
    case r.predicate
    when RDFS.label
      l,c = "is labeled", "Word used to label the subject."
    when RDF.type
      l,c = "is a", "Subject is an entity of this class."
    when RDFS.comment
      l,c = "is", "Comment: #{RDFS.comment.to_s}"
    when RDFS.subClass
      l,c = "is subclass of", RDFS.subClass.to_s
    when RDFS.domain
      l,c = "is domain of", RDFS.domain.to_s
    when OWL.sameAs
      l,c = "is the same as", "Try searching this, too."
    when OWL.Thing
      l,c = "Thing", OWL.Thing.to_s
    when DC.subject
      l,c = "ia about", "Subject: #{DC.subject.to_s}"
    when FOAF.depiction
      l,c = "has picture", "Depiction: #{FOAF.depiction}"
    when FOAF.page
      l,c = "has page", "Where to find it."
    when FOAF.primaryTopic
      l,c = "is about", "The primary topic of the subject"
    when FOAF.name
      l,c = "is called", "Name: #{FOAF.name}"
    else
      l,c = resource_label_comment(r.predicate.to_s)
    end
    {:uri => r.predicate, :label => l, :comment => c}
  end
  puts "Done!"
  puts "-----------"
  r
end

def get_unique_objects(results)
  puts "unique OBJECTS"
  r=results.uniq{|r| r.object}.map do |r|
    unless r.object.literal?
      l,c = resource_label_comment(r.object.to_s)
      {:uri => r.object, :label => l, :comment => c, :literal => false}
    else
      {:uri => r.object, :label => r.object.to_s, :comment => r.object.to_s, :literal => true}
    end
  end
  puts "Done!"
  puts "-----------"
  r
end


def only_if(results, what, resource)
  results.reject do |statement|
    case what
    when :subject
      statement.subject != resource
    when :predicate
      statement.predicate != resource
    when :object
      statement.object != resource
    else
      raise ArgumentError, "Second argument was: #{what}; and should be either: :subject, :predicate, or :object."
    end
  end  
end

def resource_label_comment(uri)
  response = fetch(uri)
  if response.class == Net::HTTPOK && !response.body.nil?
    results = only_if(parse(response), :subject, uri)
    
    label =  only_if(results, :predicate, RDFS.label.to_s).first
    if label.nil?
      label = humanize(get_resource_name(uri)) 
    else
      label = label.object.to_s
    end
    
    comment = only_if(results, :predicate, RDFS.comment.to_s).first
    if comment.nil?
      comment = label
    else
      comment = comment.object.to_s
    end
    
    return label, comment
  else
    return nil, nil
  end
end

def show?(object)
  if object.literal?
    if object.has_language?
      if object.language == :en
        true
      else
        nil
      end
    else
      true
    end
  else
    true
  end
end

class String
  def upcase?
    self.chr =~ /[A-Z]/?true:false
  end
  
  def downcase?
    self.chr =~ /[a-z]/?true:false
  end
end

def humanize(x)
  result = ""
  x.sub(/_/, ' ').chars do |ch|
    if ch.upcase?
      result += " " + ch.downcase
    else
      result += ch
    end
  end
  return result
end

def get_resource_name(uri)
  uri.split('/').last.split('#').last
end
