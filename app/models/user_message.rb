class UserMessage < ActiveRecord::Base
    belongs_to :user
    belongs_to :receiver, :class_name => "User", :foreign_key => "receiver_id"

    def self.get_number_of_messages
        #msgs = self.where("receiver_id = #{User.current.id}")
        msgs = self.find_by_sql("SELECT * FROM user_messages WHERE receiver_id = #{User.current.id} AND state = 1")
        #msgs = self.find_by_receiver_id(User.current.id)
        if msgs.class != Array && !msgs.nil?
          user_messages ||= []
          user_messages << msgs
        else
          user_messages = msgs
        end
        user_messages.nil? ? 0 : user_messages.length
    end

    def sent_directory
      return "sent"
    end

    def received_directory
      return "received"
    end

    def trash_directory
      return "trash"
    end

    def archive_directory
      return "archive"
    end

    def self.get_names_of_sender
        #msgs = self.where("receiver_id = #{User.current.id}")
        msgs = self.find_by_sql("SELECT author, id, created_at FROM user_messages WHERE receiver_id = #{User.current.id} AND state = 1 ORDER BY created_at DESC")
        #msgs = self.find_by_receiver_id(User.current.id)
        if msgs.class != Array && !msgs.nil?
          user_messages ||= []
          user_messages << msgs
        else
          user_messages = msgs
        end
        user_messages
    end

end
