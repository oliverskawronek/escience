class CreateUserMessages < ActiveRecord::Migration
  def self.up
    create_table :user_messages do |t|
      t.string :author
      t.string :subject
      t.text :body, :limit => 16384
      t.string :receiver_list
      t.string :state
      t.references :user
      t.references :receiver
      t.timestamps
    end
    add_index :user_messages, :receiver_id
    add_index :user_messages, :user_id
  end

  def self.down
    drop_table :user_messages
    remove_index :user_messages, :receiver_id
    remove_index :user_messages, :user

  end
end
