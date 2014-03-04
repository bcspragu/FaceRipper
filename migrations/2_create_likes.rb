class CreateLikes < ActiveRecord::Migration
  def change
    create_table :likes, :id => false do |t|
      t.references :status, :null => false
      t.references :user, :null => false
    end
  end
end
