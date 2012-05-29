class UserMessagesController < ApplicationController
  # GET /user_messages
  # GET /user_messages.xml
  def index
    @user_messages = UserMessage.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @user_messages }
    end
  end

  # GET /user_messages/1
  # GET /user_messages/1.xml
  def show
    @user_message = UserMessage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user_message }
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
    @user_message = UserMessage.new(params[:user_message])
    @user_message.user = User.current
    @user_message.author = User.current.login
    
    respond_to do |format|
      if @user_message.save
        format.html { redirect_to(@user_message, :notice => 'UserMessage was successfully created.') }
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
    @user_message.destroy

    respond_to do |format|
      format.html { redirect_to(user_messages_url) }
      format.xml  { head :ok }
    end
  end
end
