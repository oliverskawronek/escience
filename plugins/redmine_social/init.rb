require 'rails'
require 'redmine'

Dir::foreach(File.join(File.dirname(__FILE__), 'lib')) do |file|
  next if /\.{1,2}/ =~ file
  next unless File.exist?(File.join(File.dirname(__FILE__), 'lib',file,"init.rb"))
  p "redmine_social requires #{File.join(File.dirname(__FILE__), 'lib',file,"init.rb")}"
  require File.join(File.dirname(__FILE__), 'lib',file,"init.rb")
end

require "#{File.join(File.dirname(__FILE__), 'lib','paperclip_processors')}/cropper"
#require "hpricot"

#require_dependency 'communityengine'
#require_dependency 'plugins/enumerations_mixin/init.rb'

#require_dependency 'meta_search'
require_dependency 'will_paginate/array'

Redmine::Plugin.register :redmine_social do
  name 'redmine social plugin'
  author 'Christian Reichmann'
  description 'Extend your Redmine with social media'
  version '0.0.1'

  settings :default => { 
    'photo_content_type' => ['image/jpeg', 'image/png', 'image/gif', 'image/pjpeg', 'image/x-png', 'image/jpeg2000'],
    'photo_max_size' => '5' , 
    'photo_paperclip_options' => {
        :styles => {
            :thumb => {
              :geometry => "100x100#",
              :processors => [:cropper]
            },
            :medium => "180x180#",
            :large => "465>"
        },
        :path => ":rails_root/public/system/attachments/#{Rails.env}/files/:id/:style/:basename.:extension",
        :url => "/system/attachments/#{Rails.env}/files/:id/:style/:basename.:extension"}, 
        'photo_missing_thumb' => '',
        'photo_missing_medium' => '',
    },
    :partial =>'settings/redmine_social'

  contacts = Proc.new {"#{User.current.friendships.where("initiator = ? AND friendship_status_id = ?", false, FriendshipStatus[:pending].id).count}"}
  menu :account_menu, :user_contacts, {:controller => 'friendships', :action => 'pending', :user_id => Proc.new{"#{User.current.id}"}}, :caption => {:value_behind => contacts, :text => :friendships}, :if => Proc.new{"#{contacts.call}".to_i > 0}
  menu :account_menu, :user_contacts2, {:controller => 'friendships', :action => 'accepted', :user_id => Proc.new{"#{User.current.id}"}}, :caption => :friendships, :if => Proc.new{"#{contacts.call}".to_i == 0}
end

  
require_dependency 'application_helper'
ApplicationHelper.class_eval do
  DEFAULT_OPTIONS = {:size => 30,:alt => '',:title => '',:class => 'rounded_image'}
    def avatar(user, options = { })
      scale = options[:scale].nil? ? :thumb : options[:scale]
      options.delete(:scale)
      src = user.avatar ? user.avatar_photo_url(scale) : 'avatar.png'
      options[:size] = "#{options[:size]}x#{options[:size]}"
      options = DEFAULT_OPTIONS.merge(options)
      return image_tag src, options
    end
end