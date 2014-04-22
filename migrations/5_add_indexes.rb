class AddIndexes < ActiveRecord::Migration
  def change
    add_index :statuses, :user_id
    add_index :likes, :user_id
    add_index :likes, :status_id
  end
end
