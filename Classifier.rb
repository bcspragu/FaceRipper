require './User.rb'
require './Like.rb'
require './Status.rb'

class Classifier
  attr_accessor :status, :database, :accepted_words, :poster, :options, :results
  
  def initialize(database, status, options = {})
    @database = database
    @status = status.message.downcase.gsub(/[^\w\s]/,'')
    @poster = status.user
    @options = options
    
    @options[:classifier_constant] ||= 0.01

    #Here we make a list of words we're going to allow as features for Naive Bayes
    #But only if we are filtering words
    if options[:word_filter]
      # Strip out all statuses, downcase, remove non-word characters
      words = @database.pluck('message').join(' ').downcase.gsub(/[^\w\s]/,'').split(' ')
      # Set base frequency to 0
      word_freq = Hash.new(0)
      # Increment the frequency every time we see the word
      words.each {|word| word_freq[word] += 1}
      # Order words by frequency
      word_freq = word_freq.sort_by {|word,freq| freq}.reverse
      # Remove all the words that only show up once
      word_freq.keep_if.with_index {|w_and_f,index| w_and_f.last > 1 and index > 50}
      @accepted_words = word_freq.map {|w_and_f| w_and_f.first}
    else
      @accepted_words = @database.pluck('message').join(' ').downcase.gsub(/[^\w\s]/,'').split(' ').uniq
    end

    #In the list of statuses we check, we shouldn't consider the one we're testing
    @status_ids = @poster.statuses.pluck('id').tap {|a| a.delete(status.id)}
    return "No Data" if @status_ids.empty?

    liker_ids = Like.select('user_id').where(status_id: @status_ids).uniq.pluck('user_id')
    users_to_check = User.find(liker_ids)

    people_who_will_like_status = []

    users_to_check.each do |user|
      if classify(user)
        people_who_will_like_status << user.id 
      end
    end

    results = Hash.new(0)

    results[:hits] = (status.likes.pluck('user_id') & people_who_will_like_status).length
    results[:misses] = (status.likes.pluck('user_id') - people_who_will_like_status).length
    results[:false_positives] = (people_who_will_like_status - status.likes.pluck('user_id')).length
    
    @results = results
  end

  def classify(user)
    stat_ids = Like.where(user_id: user.id, status_id: @status_ids).pluck('status_id')
    statuses_user_likes = Status.where(id: stat_ids)
    statuses_user_doesnt_like = Status.where(id: @status_ids - stat_ids)
    # Just assume they'll like it if they've liked every status from this person in the past
    # Because we don't have any data to tell us otherwise
    
    return true if statuses_user_doesnt_like.empty?

    # Set our base probabilities to the ratio of how much they liked/didn't like in relation to the total
    p_true = statuses_user_likes.count.to_f/@status_ids.count
    p_false = statuses_user_doesnt_like.count.to_f/@status_ids.count
    @status.split(' ').each do |word|
      if @accepted_words.include? word
        p_true *= number_of_past_statuses_containing_word(statuses_user_likes,word).to_f/(statuses_user_likes.count)
        p_false *= number_of_past_statuses_containing_word(statuses_user_doesnt_like,word).to_f/(statuses_user_doesnt_like.count)
      end
    end
    #puts "User: #{user.name} true: #{p_true}, false: #{p_false}"
    p_true > p_false
  end

  def number_of_past_statuses_containing_word(statuses,word)
    count = 0
    statuses.pluck('message').each do |status|
      count += 1 if status.downcase.gsub(/[^\w\s]/,'').include? word
    end
    count == 0 ? @options[:classifier_constant] : count
  end

end
