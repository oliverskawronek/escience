require 'redmine'

Dir[File.join(Rails.root,'plugins','*')].each do |dir|
  path = File.join(dir, 'lib')
  $LOAD_PATH << path
  #ActiveSupport::Dependencies.load_paths << path
  #ActiveSupport::Dependencies.load_once_paths.delete(path)
  ActiveSupport::Dependencies.autoload_paths << path
  ActiveSupport::Dependencies.autoload_once_paths.delete(path)
end

# Patches to the Redmine core.
if Rails::VERSION::MAJOR >= 3
    require_dependency 'comment'
    Comment.send(:include, RedmineBlogs::Patches::CommentPatch)

    require_dependency 'application_controller'
    ApplicationController.send(:include, RedmineBlogs::Patches::ApplicationControllerPatch)

    #require_dependency 'acts_as_taggable'
else
  require 'dispatcher'

  Dispatcher.to_prepare :redmine_blogs do

    require_dependency 'comment'
    Comment.send(:include, RedmineBlogs::Patches::CommentPatch)

    require_dependency 'application_controller'
    ApplicationController.send(:include, RedmineBlogs::Patches::ApplicationControllerPatch)

    require_dependency 'acts_as_taggable'
  end
end



Redmine::Plugin.register :redmine_blogs do
  name 'Redmine Blogs plugin'
  author 'A. Chaika, Kyanh, Eric Davis'
  description 'Redmine Blog plugin'
  version '0.2.0-edavis10'

  permission :manage_blogs, :blogs => [:new, :edit, :destroy_comment, :destroy]
  permission :comment_blogs, :blogs => :add_comment
  permission :view_blogs, :blogs => [:index, :show]

  menu :top_menu, :blogs, { :controller => 'blogs', :action => 'index' }, :caption => 'Blogs', :if => Proc.new {
    User.current.allowed_to?({:controller => 'blogs', :action => 'index'}, nil, {:global => true})
  }

end
Redmine::Activity.map do |activity|
  activity.register(:blogs,{:class_name => 'Blog'})
end

class RedmineBlogsHookListener < Redmine::Hook::ViewListener
  render_on :view_layouts_base_html_head, :inline => "<%= stylesheet_link_tag 'stylesheet', :plugin => 'redmine_blogs' %>"
end 
require 'redmine_blogs/hooks/view_account_left_middle_hook'
