class CreateUserMessages < ActiveRecord::Migration
  def self.up
    create_table :user_messages do |t|
      t.string :author
      t.string :subject
      t.string :body
      t.string :receiver
      t.string :state
      t.references :user
      t.timestamps
    end
  end

  def self.down
    drop_table :user_messages
  end
end
