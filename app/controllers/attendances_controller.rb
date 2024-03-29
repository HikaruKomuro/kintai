class AttendancesController < ApplicationController
  before_action :set_user, only: :edit_one_month
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :set_one_month, only: :edit_one_month
  
UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"

  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    
    # 出勤時間が未登録であることを判定します。
    if @attendance.started_at.nil?
      if @attendance.update_attributes(started_at: DateTime.current.change(sec: 0).round_to(15.minutes))
        @attendance.update_attributes(first_started_at: DateTime.current.change(sec: 0).round_to(15.minutes))
        @user.update_attributes(working: 1)
        flash[:info] = "おはようございます！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update_attributes!(finished_at: DateTime.current.change(sec: 0).round_to(15.minutes))
        @attendance.update_attributes!(first_finished_at: DateTime.current.change(sec: 0).round_to(15.minutes))
        @user.update_attributes(working: 0)
        flash[:info] = "お疲れ様でした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
  end
  
  def edit_one_month
    @users = User.where(superior: "2")
    @request = Request.new
  end
  
  def update_one_month
    ActiveRecord::Base.transaction do
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        attendance.update_attributes!(item)
      end
    end
      flash[:success] = "更新に成功しました。"
      redirect_to user_url(date: params[:date])
    rescue ActiveRecord::RecordInvalid
      flash[:danger] = "無効な入力があったので、更新がキャンセルされました。"
      redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end
  
  private
    
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :note])[:attendances]
    end
    
end