class Result
  attr_reader :subject, :predicate, :object
  def initialize(subject, predicate, object)
    @subject = subject
    @predicate = predicate
    @object = object
  end
end