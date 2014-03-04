require 'open-uri'
require 'json'
require './User.rb'
require './Like.rb'
require './Status.rb'

facebook_config = YAML::load(File.open('config/facebook.yml'))
access_token = facebook_config['access_token']
user_id = facebook_config['user_id']

url = "https://graph.facebook.com/#{user_id}?access_token=#{access_token}&fields=id,name,friends.limit(1).fields(name,statuses.limit(50).fields(likes,message))";

content = JSON.parse(open(url).read)

user = User.where(name: content['name'], facebook_id: content['id']).first_or_create

friend_json = content['friends']['data'].first

get_statuses(friend_json)

friend_json = content['friends']
while friend_json['paging'] and friend_json['paging']['next']
    url = friend_json['paging']['next']
    content = JSON.parse(open(url).read)
    friend_json = content
    p friend_json
    get_statuses(friend_json['data'].first)
end

BEGIN {
def add_status(friend,status_data)
  status = Status.create(message: status_data['message'], user_id: friend.id)
  unless status_data['likes'].nil?
    status_data['likes']['data'].each do |like_data|
      liker = User.where(name: like_data['name'], facebook_id: like_data['id']).first_or_create
      status.likes.create(user_id: liker.id)
    end
  end
end

def get_statuses(user_json)
  friend = User.where(name: user_json['name'], facebook_id: user_json['id']).first_or_create
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
}
