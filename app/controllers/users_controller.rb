# -*- coding: utf-8 -*-
class UsersController < ApplicationController
  before_filter :authenticate, :only => [:index, :edit, :update, :destroy]
  before_filter :correct_user, :only => [:edit, :update]
  before_filter :admin_user,   :only => :destroy

  ##
  # userの一覧を表示する
  def index
    @title = "All users"
    @users = User.paginate(:page => params[:page])
  end

  ##
  # ログインしているuserを表示
  def show
    @user = User.find(params[:id])
    @microposts = @user.microposts.paginate(:page => params[:page])
    @title = @user.name
  end

  ##
  # 新規user作成画面を表示する
  def new
    if signed_in?
      redirect_to root_path
    else
      @user = User.new
      @title = "Sign up"
    end
  end

  ##
  # 新規userを作成する
  def create
    if signed_in?
      redirect_to root_path
    else
      @user = User.new(params[:user])
      if @user.save
        sign_in @user
        flash[:success] = "Welcome to the Sample App!"
        redirect_to @user
      else
        @title = "Sign up"
        params[:user][:password] = params[:user][:password_confirmation] = ""
        render 'new'
      end
    end
  end

  ##
  # user編集画面を表示する
  def edit
    @title = "Edit user"
  end

  ##
  # user情報を更新する
  def update
    if @user.update_attributes(params[:user])
      flash[:success] = "Profile updated."
      redirect_to @user
    else
      @title = "Edit user"
      render 'edit'
    end
  end

  ##
  # userを破棄する
  def destroy
    user = User.find(params[:id])
    unless current_user?(user)
      user.destroy
      flash[:success] = "User destroyed."
    end
    redirect_to users_path
  end

  private

  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_path) unless current_user?(@user)
  end

  def admin_user
    redirect_to(root_path) unless current_user.admin?
  end
end
