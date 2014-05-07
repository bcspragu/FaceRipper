require './Classifier.rb'

random = Random.new(1) #Set a seed

ids = Like.pluck('status_id').sort_by {random.rand}[0..19]

statuses_to_test = Status.find(ids)

[0,0.001,0.01,0.1].each do |o|
  puts "Running with #{o}"
  statuses_to_test.each do |status|
    c = Classifier.new(Status.where('id != ?',status.id),status,{classifier_constant: o})
    p c.results
  end
end
