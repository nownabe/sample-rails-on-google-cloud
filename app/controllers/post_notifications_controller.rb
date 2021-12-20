class PostNotificationsController < ApplicationController
  before_action :set_post_notification, only: %i[ show edit update destroy ]

  # GET /post_notifications or /post_notifications.json
  def index
    @post_notifications = PostNotification.all
  end

  # GET /post_notifications/1 or /post_notifications/1.json
  def show
  end

  # GET /post_notifications/new
  def new
    @post_notification = PostNotification.new
  end

  # GET /post_notifications/1/edit
  def edit
  end

  # POST /post_notifications or /post_notifications.json
  def create
    @post_notification = PostNotification.new(post_notification_params)

    respond_to do |format|
      if @post_notification.save
        format.html { redirect_to post_notification_url(@post_notification), notice: "Post notification was successfully created." }
        format.json { render :show, status: :created, location: @post_notification }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @post_notification.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /post_notifications/1 or /post_notifications/1.json
  def update
    respond_to do |format|
      if @post_notification.update(post_notification_params)
        format.html { redirect_to post_notification_url(@post_notification), notice: "Post notification was successfully updated." }
        format.json { render :show, status: :ok, location: @post_notification }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @post_notification.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /post_notifications/1 or /post_notifications/1.json
  def destroy
    @post_notification.destroy

    respond_to do |format|
      format.html { redirect_to post_notifications_url, notice: "Post notification was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post_notification
      @post_notification = PostNotification.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def post_notification_params
      params.require(:post_notification).permit(:post_id, :message)
    end
end
