# Redmine - project management software
# Copyright (C) 2006-2012  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class ProjectsController < ApplicationController
  menu_item :overview
  menu_item :roadmap, :only => :roadmap
  menu_item :settings, :only => :settings

  before_filter :find_project, :except => [ :index, :list, :new, :create, :copy ]
  before_filter :authorize, :except => [ :index, :list, :new, :create, :copy, :archive, :unarchive, :destroy, :add_attachment]
  before_filter :require_login, :only => [:show]
  before_filter :authorize_global, :only => [:new, :create]
  before_filter :require_admin, :only => [ :copy, :archive, :unarchive, :destroy ]
  accept_rss_auth :index
  accept_api_auth :index, :show, :create, :update, :destroy

  after_filter :only => [:create, :edit, :update, :archive, :unarchive, :destroy] do |controller|
    if controller.request.post?
      controller.send :expire_action, :controller => 'welcome', :action => 'robots'
    end
  end

  helper :sort
  include SortHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :issues
  helper :queries
  include QueriesHelper
  helper :repositories
  include RepositoriesHelper
  include ProjectsHelper
  include AttachmentsHelper
  include ApplicationHelper

  # Lists visible projects
  def index
    respond_to do |format|
      format.html {
        scope = Project
        unless params[:closed]
          scope = scope.active
        end

        if !params[:sub].nil? && session[:current_view_of_eScience] == "0"
          projects = scope.own(User.current)
        else
          projects = scope.visible.all
        end
        @name_dir = 'desc'
        @newest_dir = 'desc'
        if params[:order] == 'name'
          @name_dir = params[:dir] == 'asc' ? 'desc' : 'asc'
        elsif params[:order] == 'created_on'
          @newest_dir = params[:dir] == 'desc' ? 'asc' : 'desc'
        end
        @projects = project_nested_list(projects)

      }
      format.api  {
        @offset, @limit = api_offset_and_limit
        @project_count = Project.visible.count
        @projects = Project.visible.all(:offset => @offset, :limit => @limit, :order => 'lft')
      }
      format.atom {
        projects = Project.visible.find(:all, :order => 'created_on DESC',
                                              :limit => Setting.feeds_limit.to_i)
        render_feed(projects, :title => "#{Setting.app_title}: #{l(:label_project_latest)}")
      }
    end
  end
  
  def project_nested_list(projects)
    if projects.any?
      if params[:order] == 'created_on'
        projects_with_activities = []
        projects.each do |project|
          @activity = Redmine::Activity::Fetcher.new(User.current, :project => project,
                                                                   :with_subprojects => false,
                                                                   :author => User.current)
          events = @activity.events(nil, nil,{:limit=>1})
          unless events.empty?
            event = events.first
            if (event[:updated_on]) && event[:updated_on].to_i > project.updated_on.to_i
              projects_with_activities << {:last_activity => event.updated_on, :project => project}
            elsif event[:created_on].to_i > project.updated_on.to_i
              projects_with_activities << {:last_activity => event.created_on, :project => project}
            else
              projects_with_activities << {:last_activity => project.updated_on, :project => project}
            end
          else
            projects_with_activities << {:last_activity => project.updated_on, :project => project}
          end
        end
        if params[:dir].nil? || params[:dir] == 'desc'
          projects_with_activities.sort! { |a, b| [b[:last_activity], b[:project]] <=> [a[:last_activity], a[:project]] }
        else 
          projects_with_activities.sort! { |a, b| [a[:last_activity], a[:project]] <=> [b[:last_activity], b[:project]] }
        end
        projects = projects_with_activities
      end


      parents = []
      projects.each do |project_element|
        project = projects_with_activities.nil? ? project_element : project_element[:project]
        unless params[:show_all]
          projects_hierarchy = project.hierarchy()
          start = 0
          if projects_hierarchy.size() > 1
            projects_hierarchy.slice!(0)
            start = 1
          end
          parent = projects_hierarchy[0]
          if parent[:id] != 6 && !parents.any? { |b| b[:id] == parent[:id]}
            newest = projects_with_activities.nil? ? project_element.id : project_element[:project].id
            last_activity = projects_with_activities.nil? ? project_element.updated_on : project_element[:last_activity]
            parents << {:id => parent.id, :project => parent, :date => last_activity, :start => start, :newest => newest}
          end
        else
          parents << {:id => project.id, :project => project, :date => project.updated_on, :start => 0, :newest => project.id}
        end
      end
      
      if params[:order] == 'name' || params[:order].nil?
        if params[:dir].nil? || params[:dir] == 'asc'
          parents.sort! { |a,b| a[:project].name.downcase <=> b[:project].name.downcase }
        else
          parents.sort! { |a,b| b[:project].name.downcase <=> a[:project].name.downcase }
        end
      end
      
      return parents
    end
  end

  def new
    @issue_custom_fields = IssueCustomField.find(:all, :order => "#{CustomField.table_name}.position")
    @trackers = Tracker.all
    @project = Project.new
    @project.safe_attributes = params[:project]
  end

  def create
    @issue_custom_fields = IssueCustomField.find(:all, :order => "#{CustomField.table_name}.position")
    @trackers = Tracker.all
    @project = Project.new
    if Setting.sequential_project_identifiers?
      identifier_words = params[:project][:name].downcase.split
      word_nr = 0
      identifier = identifier_words[word_nr]
      word_nr = word_nr + 1
      while !Project.find_by_identifier(identifier).nil? && word_nr<identifier_words.length
        identifier += "_"+ identifier_words[word_nr]
        word_nr = word_nr + 1
      end
      params[:project][:identifier] = identifier
    end
    params[:project][:description] = convertHtmlToWiki(params[:project][:description])
    @project.safe_attributes = params[:project]
    @project.creator = User.current.id
    
    if Project.find_by_name(params[:project][:name]).nil? && params[:project][:name].length<51 && validate_parent_id && @project.save!
      @project.set_allowed_parent!(params[:project]['parent_id']) if params[:project].has_key?('parent_id')
      # Add current user as a project member if he is not admin
      unless User.current.admin?
        r = Role.givable.find_by_id(Setting.new_project_user_role_id.to_i) || Role.givable.first
        m = Member.new(:user => User.current, :roles => [r])
        @project.members << m
      end
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to(params[:continue] ?
            {:controller => 'projects', :action => 'new', :project => {:parent_id => @project.parent_id}.reject {|k,v| v.nil?}} :
            {:controller => 'projects', :action => 'show', :id => @project}
          )
        }
        format.api  { render :action => 'show', :status => :created, :location => url_for(:controller => 'projects', :action => 'show', :id => @project.id) }
      end
    else
      respond_to do |format|
        format.html { 
          if params[:project][:name].length>50
            flash[:notice] = l(:error_projectname_tolong)
          elsif Project.find_by_name(params[:project][:name]).nil?
            flash[:notice] = l(:error_projectname_exists)
          else 
            flash[:notice] = l(:error_projectname_exists)
          end 
          render :action => 'new' 
        }
        format.api  { render_validation_errors(@project) }
      end
    end

  end

  def copy
    @issue_custom_fields = IssueCustomField.find(:all, :order => "#{CustomField.table_name}.position")
    @trackers = Tracker.sorted.all
    @root_projects = Project.find(:all,
                                  :conditions => "parent_id IS NULL AND status = #{Project::STATUS_ACTIVE}",
                                  :order => 'name')
    @source_project = Project.find(params[:id])
    if request.get?
      @project = Project.copy_from(@source_project)
      if @project
        @project.identifier = Project.next_identifier if Setting.sequential_project_identifiers?
      else
        redirect_to :controller => 'admin', :action => 'projects'
      end
    else
      Mailer.with_deliveries(params[:notifications] == '1') do
        @project = Project.new
        @project.safe_attributes = params[:project]
        if validate_parent_id && @project.copy(@source_project, :only => params[:only])
          @project.set_allowed_parent!(params[:project]['parent_id']) if params[:project].has_key?('parent_id')
          flash[:notice] = l(:notice_successful_create)
          redirect_to :controller => 'projects', :action => 'settings', :id => @project
        elsif !@project.new_record?
          # Project was created
          # But some objects were not copied due to validation failures
          # (eg. issues from disabled trackers)
          # TODO: inform about that
          redirect_to :controller => 'projects', :action => 'settings', :id => @project
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to :controller => 'admin', :action => 'projects'
  end
	
  # Show @project
  def show
    session[:selected_project] = @project.id 

    if params[:jump]
      # try to redirect to the requested menu item
      redirect_to_project_menu_item(@project, params[:jump]) && return
    end

    @users_by_role = @project.users_by_role 
    @subprojects = @project.children.visible.all
    @topproject = @project.parent
    @news = @project.news.find(:all, :limit => 5, :include => [ :author, :project ], :order => "#{News.table_name}.created_on DESC")
    @trackers = @project.rolled_up_trackers

    cond = @project.project_condition(Setting.display_subprojects_issues?)

    @issues = Issue.visible.open.where(:parent_id => nil, :project_id => @project.id)
    @open_issues_by_tracker = Issue.visible.open.where(cond).count(:group => :tracker)
    @total_issues_by_tracker = Issue.visible.where(cond).count(:group => :tracker)

    if User.current.allowed_to?(:view_time_entries, @project)
      @total_hours = TimeEntry.visible.sum(:hours, :include => :project, :conditions => cond).to_f
    end

    activities = activity_index_for_project
    unless activities.empty?
      last_event = activities.first[1][0]
      @last_update = @project.updated_on
      if (last_event[:updated_on]) && last_event[:updated_on].to_i > @project.updated_on.to_i
        @last_update = last_event.updated_on
      elsif last_event[:created_on].to_i > @project.updated_on.to_i
        @last_update = last_event.created_on
      end
    else
      @last_update = @project.updated_on
    end 
    
    @key = User.current.rss_key

    respond_to do |format|
      format.html
      format.api
    end
  end

  def settings
    @issue_custom_fields = IssueCustomField.find(:all, :order => "#{CustomField.table_name}.position")
    @issue_category ||= IssueCategory.new
    @member ||= @project.members.new
    @trackers = Tracker.all
    @wiki ||= @project.wiki
  end

  def update
    params[:project][:description] = convertHtmlToWiki(params[:project][:description])
    @project.safe_attributes = params[:project]
    if validate_parent_id && @project.save
      @project.set_allowed_parent!(params[:project]['parent_id']) if params[:project].has_key?('parent_id')
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to :action => 'settings', :id => @project
        }
        format.js {
          @id = 'description'
          @content = textilizable(@project.description)
          render :partial => 'update'
        }
        format.api  { render_api_ok }
      end
    else
      respond_to do |format|
        format.html {
          settings
          render :action => 'settings'
        }
        format.api  { render_validation_errors(@project) }
      end
    end
  end

  def add_attachment
    attachments = Attachment.attach_files(@project, params[:attachments])
#    p attachments[:errors]
    errors = (attachments[:files].empty? && attachments[:unsaved].empty?) ? [l(:no_file_given)] : []
    attachments[:errors].each do |error|
      error.each do |k,v| 
        errors << l(k) + " #{v.first}" if (k != :base)
        errors << v.flatten if (k == :base)
      end
    end 
    if errors.empty?
      respond_to do |format|
        format.js { render :partial => 'update_attachment'}
      end
    else
      respond_to do |format|
        format.json {
          render :js => "$.notification({ message:'#{errors.join('\\n')}', type:'error' })";
        }
      end
    end
  end

  
  def modules
    @project.enabled_module_names = params[:enabled_module_names]
    flash[:notice] = l(:notice_successful_update)
    redirect_to :action => 'settings', :id => @project, :tab => 'modules'
  end

  def archive
    if request.post?
      unless @project.archive
        flash[:error] = l(:error_can_not_archive_project)
      end
    end
    redirect_to(url_for(:controller => 'admin', :action => 'projects', :status => params[:status]))
  end

  def unarchive
    @project.unarchive if request.post? && !@project.active?
    redirect_to(url_for(:controller => 'admin', :action => 'projects', :status => params[:status]))
  end

  def close
    @project.close
    redirect_to project_path(@project)
  end

  def reopen
    @project.reopen
    redirect_to project_path(@project)
  end

  # Delete @project
  def destroy
    session[:selected_project] = nil if session[:selected_project] == @project.id 
    @project_to_destroy = @project
    if api_request? || params[:confirm]
      @project_to_destroy.destroy
      respond_to do |format|
        format.html { redirect_to :controller => 'admin', :action => 'projects' }
        format.api  { render_api_ok }
      end
    end
    # hide project in layout
    @project = nil
  end

  private

  # Validates parent_id param according to user's permissions
  # TODO: move it to Project model in a validation that depends on User.current
  def validate_parent_id
    return true if User.current.admin?
    parent_id = params[:project] && params[:project][:parent_id]
    if parent_id || @project.new_record?
      parent = parent_id.blank? ? nil : Project.find_by_id(parent_id.to_i)
      unless @project.allowed_parents.include?(parent)
        @project.errors.add :parent_id, :invalid
        return false
      end
    end
    true
  end
end
