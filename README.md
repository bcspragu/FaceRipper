FaceRipper
==========

Pulls my friends facebook statuses and likes into a database, which can be manipulated with ActiveRecord

Usage:

1. Create two files: config/database.yml and facebook.yml.
2. Fill database.yml in like Rails, except without the top level ..._development, because we only have one environment.
3. Fill facebook.yml with two fields: access_token and user_id, where user_id is your user_id and access_token is your Facebook-given access token.
4. ruby Driver.rb

Done.

The Classifer.rb file attempts to do Naive Bayes classification to find out who will like a status based on it's contents...it's pretty bad right now.
