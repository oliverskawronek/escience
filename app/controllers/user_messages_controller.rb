class UserMessagesController < ApplicationController

  before_filter :require_login
  

  # GET /user_messages
  # GET /user_messages.xml
  def index
    dir = "received"
    if !params[:directory].nil?
      dir = case params[:directory]
        when "trash" then UserMessage.trash_directory
        when "sent" then UserMessage.sent_directory
        when "archive" then UserMessage.archive_directory
        when "received" then UserMessage.received_directory
        else ""
      end
      @directory = dir
    end
    where = "directory = "
    where += (dir == "sent")? "'#{dir}' AND user_id=#{User.current.id}" : "'#{dir}' AND state<>3 AND receiver_id=#{User.current.id}"
    where += (dir == "trash")? " AND state=2" : " AND state<>2"
    msgs = UserMessage.find_by_sql("SELECT * FROM user_messages WHERE #{where} ORDER BY created_at DESC")
    if msgs.class != Array && !msgs.nil?
      @user_messages ||= []
      @user_messages << msgs
    else
      @user_messages = msgs
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @user_messages }
    end
  end

  # GET /user_messages/1
  # GET /user_messages/1.xml
  def show
    @user_message = UserMessage.find(params[:id])
    @user_message.state = 0
    @user_message.save!
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user_message }
    end
  end

  def sent_messages
    msgs = UserMessage.find_by_user_id(User.current.id)
    if msgs.class != Array
      @user_messages ||= []
      @user_messages << msgs
    else
      @user_messages = msgs
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @user_messages }
    end
  end

  # GET /user_messages/new
  # GET /user_messages/new.xml
  def new
    @user_message = UserMessage.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user_message }
    end
  end

  # GET /user_messages/1/edit
  def edit
    @user_message = UserMessage.find(params[:id])
  end

  # POST /user_messages
  # POST /user_messages.xml
  def create
    p params[:user_message]["receiver"]
    recv = User.find_by_mail(params[:user_message]["receiver"])
    if recv.nil?
      @user_massage = UserMessage.new()
      respond_to do |format|
        format.html { redirect_to(:action => 'new', :notice => 'Receiver not known') }
        format.xml  { render :xml => @user_message.errors, :status => :unprocessable_entity }
      end
      return 
    end
    @user_message = UserMessage.new()
    @user_message.body = params[:user_message]["body"]
    @user_message.subject = params[:user_message]["subject"]
    @user_message.user = User.current
    @user_message.author = "#{User.current.lastname}, #{User.current.firstname}"
    @user_message.receiver_id = recv.id
    @user_message.state = 1
    @user_message.directory = UserMessage.received_directory

    @user_message_clone = @user_message.clone
    @user_message_clone.state = 3
    @user_message_clone.directory = UserMessage.sent_directory

    respond_to do |format|
      if (@user_message.save && @user_message_clone.save)
        format.html { redirect_to(:action => 'new', :notice => 'UserMessage was successfully created.') }
        format.xml  { render :xml => @user_message, :status => :created, :location => @user_message }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user_message.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /user_messages/1
  # PUT /user_messages/1.xml
  def update
    @user_message = UserMessage.find(params[:id])

    respond_to do |format|
      if @user_message.update_attributes(params[:user_message])
        format.html { redirect_to(@user_message, :notice => 'UserMessage was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user_message.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /user_messages/1
  # DELETE /user_messages/1.xml
  def destroy
    @user_message = UserMessage.find(params[:id])
    if !params[:directory].nil? && params[:directory] == UserMessage.trash_directory
      @user_message.destroy
    else
      @user_message.state = 2
      @user_message.directory = UserMessage.trash_directory
      #@user_message.save
    end

    respond_to do |format|
      format.html { redirect_to(request.referer, :notice => l(:text_message_delete_done)) }
      format.xml  { head :ok }
    end
  end

  def archive
    @user_message = UserMessage.find(params[:id])
    @user_message.directory = UserMessage.archive_directory
    if (@user_message.state == 2) 
      @user_message.state = 0
    end
    @user_message.save
    #@user_message.destroy

    respond_to do |format|
      format.html { redirect_to(request.referer, :notice => l(:text_message_archive_done)) }
      format.xml  { head :ok }
    end
  end
  
  def emptytrash
    err = UserMessage.delete_all "user_id=#{User.current.id} AND state=2"
    respond_to do |format|
      if !err
        format.html { redirect_to(request.referer, :notice => l(:text_message_emptytrash_done)) }
      else
        format.html { redirect_to(request.referer, :notice => l(:text_message_emptytrash_error)) }
      end
      format.xml  { head :ok }
    end
  end
end
