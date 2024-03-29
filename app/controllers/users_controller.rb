class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info, :one_month_output, :approval_logs, :logs, :superior_user?, :corect_user2]
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: [:destroy, :index, :import, :index_working]
  before_action :set_one_month, only: [:show, :one_month_output, :approval_logs]
  before_action :confirm_show, only: [:show]
  before_action :corect_user2, only: [:approval_logs]

  def index
    @users = User.paginate(page: params[:page], per_page: 5).search(params[:search]).order(:id)
  end

  def import
    User.import(params[:file])
    flash[:success] = "CSVファイルをインポートしました。"
    redirect_to users_url
  end

  def index_working
    @users = []
    User.all.each do |user|
      if user.attendances.any?{|a| ( Date.today && !a.started_at.blank? && a.finished_at.blank?)}
        @users.push(user)
      end
    end
  end
  
  def show
    redirect_to users_path if current_user.admin?
    if current_user?(@user) || current_user.requests.pluck(:applicant).include?(@user.id)
      @worked_sum = @attendances.where.not(started_at: nil).count
      @attendance1 = @user.attendances.find_by(worked_on: @first_day)
      @users = User.where(superior: "2")
      @request = Request.new
      @requests1 = @user.requests.where(category: 1).order(:applicant)
      @requests2 = @user.requests.where(category: 2).order(:applicant)
      @requests3 = @user.requests.where(category: 3).order(:applicant)
      @applied_users1 = @requests1.pluck(:applicant).uniq
      @applied_users2 = @requests2.pluck(:applicant).uniq
      @applied_users3 = @requests3.pluck(:applicant).uniq
    end
  end
  
  def one_month_output
    respond_to do |format|
      format.html do
          #html用の処理を書く
      end 
      format.csv do
          #csv用の処理を書く
      end
    end
  end
  
  def approval_logs
    @attendances_all = @user.attendances.where(status2: 2).order(:worked_on)
    @attendances = @attendances_all.where(worked_on: @first_day..@last_day)
  end
  
  def logs
    @date = Date.new( params["date(1i)"].to_i, params["date(2i)"].to_i)
    redirect_to approval_logs_user_url(@user, date: @date.beginning_of_month)
  end
  
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = '新規作成に成功しました。'
      redirect_to @user
    else
      render :new
    end
  end

  def edit
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      flash[:success] = "ユーザー情報を更新しました。"

      if current_user.admin?
        redirect_to users_url 
      else
        redirect_to @user
      end
    else
      render :edit      
    end
  end

  def destroy
    @user.destroy
    flash[:success] = "#{@user.name}のデータを削除しました。"
    redirect_to users_url
  end

  def edit_basic_info
  end

  def update_basic_info
    if @user.update_attributes(basic_info_params)
      flash[:success] ="#{@user.name}の基本情報を更新しました"
    else
      flash[:danger] = "#{@user.name}の更新は失敗しました。<br>" + @user.errors.full_messages.join("<br>")
    end
    redirect_to users_url
  end
  
  def search
    @users = User.search(params[:search])
  end
 
  
  private

    def user_params
      params.require(:user).permit(:name, :email, :affiliation, :password, :password_confirmation, :employee_number, :uid, :basic_time, :designated_work_start_time, :designated_work_end_time)
    end
    
    
    
    def basic_info_params
      params.require(:user).permit(:department, :work_time, :basic_time)
    end

    def logged_in_user
      unless logged_in?
         store_location
        flash[:danger] = "ログインしてください"
        redirect_to login_url
      end
    end
    
    # 正しいユーザーかどうか確認
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless (@user == current_user) || current_user.admin?
    end
    
    def corect_user2
      redirect_to(root_url) unless @user == current_user
    end
    
    def confirm_show
      redirect_to(root_url) unless current_user?(@user) || (params[:confirm] == Digest::MD5.hexdigest(@user.name))
    end
    
end