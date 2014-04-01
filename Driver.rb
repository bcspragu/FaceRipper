require 'open-uri'
require 'json'
require './User.rb'
require './Like.rb'
require './Status.rb'

facebook_config = YAML::load(File.open('config/facebook.yml'))
access_token = facebook_config['access_token']
user_id = facebook_config['user_id']

friend_query = "https://graph.facebook.com/#{user_id}?access_token=#{access_token}&fields=id,name,friends.fields(name,id)"

query = JSON.parse(open(friend_query).read)

load_friends(query['friends'])

User.where(name: query['name'], facebook_id: query['id']).first_or_create

User.all.each do |user|
  status_query = "https://graph.facebook.com/#{user_id}?access_token=#{access_token}&fields=id,name,friends.uid(#{user.facebook_id}).fields(name,statuses)"
  get_statuses(user,(JSON.parse(open(status_query).read)['friends'] || [])['data'].first)
end

#statuses_without_likes = Status.pluck('id') - Like.select('status_id').uniq.pluck('status_id')

BEGIN {

def add_status(friend,status_data)
  status = Status.create(message: status_data['message'], user_id: friend.id)
  unless status_data['likes'].nil?
    get_likes(status,status_data['likes']);
  end
end

def get_statuses(friend,user_json)
  return unless user_json['statuses'] and user_json['statuses']['data']
  user_json['statuses']['data'].each do |status_data|
    add_status(friend,status_data)
  end
  status_info = user_json['statuses']
  while status_info['paging'] and status_info['paging']['next']
    url = status_info['paging']['next']
    content = JSON.parse(open(url).read)
    content['data'].each do |status_data|
      add_status(friend,status_data)
    end
    status_info = content
  end
end

def get_likes(status,like_json)
  like_json['data'].each do |like_data|
    liker = User.where(facebook_id: like_data['id']).first
    status.likes.create(user_id: liker.id) if liker
  end
  get_likes(status,JSON.parse(open(like_json['paging']['next']).read)) if like_json['paging']['next']
end

def load_friends(friend_json)
  friends_from_data(friend_json['data'])
  while friend_json['paging'] and friend_json['paging']['next']
    friend_json = JSON.parse(open(friend_json['paging']['next']).read)
    friends_from_data(friend_json['data'])
  end
end

def friends_from_data(data)
  data.each do |user_json|
    User.where(name: user_json['name'], facebook_id: user_json['id']).first_or_create
  end
end
}
