# Redmine - project management software
# Copyright (C) 2006-2011  Jean-Philippe Lang
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

class DocumentsController < ApplicationController
  default_search_scope :documents
  model_object Document
  before_filter :find_project_by_project_id, :only => [:index, :new, :create]
  before_filter :find_model_object, :except => [:index, :new, :create]
  before_filter :find_project_from_association, :except => [:index, :new, :create]
  before_filter :authorize

  helper :attachments

  def index
    @sort_by = %w(category date title author).include?(params[:sort_by]) ? params[:sort_by] : 'category'
    documents = @project.documents.find :all, :include => [:attachments, :category]
    case @sort_by
    when 'date'
      @grouped = documents.group_by {|d| d.updated_on.to_date }
    when 'title'
      @grouped = documents.group_by {|d| d.title.first.upcase}
    when 'author'
      @grouped = documents.select{|d| d.attachments.any?}.group_by {|d| d.attachments.last.author}
    else
      @grouped = documents.group_by(&:category)
    end
    @document = @project.documents.build
    render :layout => false if request.xhr?
  end

  def show
    @attachments = @document.attachments.find(:all, :order => "created_on DESC")
  end

  def new
    @document = @project.documents.build
    @document.safe_attributes = params[:document]
  end

  def create
    @document = @project.documents.build
    @document.safe_attributes = params[:document]
    @document.save_attachments(params[:attachments])
    if @document.save
      render_attachment_warning_if_needed(@document)
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index', :project_id => @project
    else
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    @document.safe_attributes = params[:document]
    if request.put? and @document.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'show', :id => @document
    else
      render :action => 'edit'
    end
  end

  def destroy
    @document.destroy if request.delete?
    redirect_to :controller => 'documents', :action => 'index', :project_id => @project
  end

  def add_attachment
    attachments = Attachment.attach_files(@document, params[:attachments])
    render_attachment_warning_if_needed(@document)

    Mailer.deliver_attachments_added(attachments[:files]) if attachments.present? && attachments[:files].present? && Setting.notified_events.include?('document_added')
    redirect_to :action => 'show', :id => @document
  end
end
