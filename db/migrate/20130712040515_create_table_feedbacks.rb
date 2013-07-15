class CreateTableFeedbacks < ActiveRecord::Migration
  def up
    create_table :feedbacks do |t|
      t.integer :user_id, :null => false
      t.string :email, :default => ""
      t.string :message, :default => ""
      t.timestamps
    end
  end

  def down
  end
end
