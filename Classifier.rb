require './User.rb'
require './Like.rb'
require './Status.rb'

puts "Please enter status: "
@status = gets.chomp.downcase.gsub(/[^\w\s]/,'')
puts "Please enter name of user: "
name = gets.chomp

words = Status.pluck('message').join(' ').downcase.gsub(/[^\w\s]/,'').split(' ')

word_freq = Hash.new(0)

words.each {|word| word_freq[word] += 1}

word_freq = word_freq.sort_by {|word,freq| freq}.reverse

word_freq.keep_if.with_index {|w_and_f,index| w_and_f.last > 1 and index > 50}

accepted_words = word_freq.map {|w_and_f| w_and_f.first}

@poster = User.where(name: name).first

@status_ids = @poster.statuses.pluck('id')

liker_ids = Like.select('user_id').where(status_id: @status_ids).uniq.pluck('user_id')

users_to_check = User.find(liker_ids)

def classify(user)
  stat_ids = Like.where(user_id: user.id, status_id: @status_ids).pluck('status_id')
  statuses_user_likes = Status.where(id: stat_ids)
  statuses_user_doesnt_like = Status.where(id: @status_ids - stat_ids)
  p_true = statuses_user_likes.count.to_f/@status_ids.count
  p_false = statuses_user_doesnt_like.count.to_f/@status_ids.count
  @status.split(' ').each do |word|
    p_true *= number_of_past_statuses_containing_word(statuses_user_likes,word).to_f/statuses_user_likes.count
    p_false *= number_of_past_statuses_containing_word(statuses_user_doesnt_like,word).to_f/statuses_user_doesnt_like.count
  end
  puts "User: #{user.name} true: #{p_true}, false: #{p_false}"
  p_true > p_false
end

def number_of_past_statuses_containing_word(statuses,word)
  count = 0
  statuses.pluck('message').each do |status|
    count += 1 if status.downcase.gsub(/[^\w\s]/,'').include? word
  end
  count == 0 ? 0.1 : count
end

people_who_will_like_status = []

users_to_check.each do |user|
  people_who_will_like_status << user if classify(user)
end

people_who_will_like_status.sort_by {|user| user.name}.each do |user|
  puts user.name
end
