# -*- coding: utf-8 -*-

module SessionsHelper
  ##
  # +user+のサインインを実行する
  # @param [User] ログインするユーザ
  def sign_in(user)
    cookies.permanent.signed[:remember_token] = [user.id, user.salt]
    self.current_user = user
  end

  ##
  # 現在ログイン中のユーザを設定する
  # @param [User] 現在ログイン中のユーザ
  def current_user=(user)
    @current_user = user
  end

  ##
  # remember tokenより、現在ログイン中のユーザを返す
  # @return [User] 現在ログイン中のユーザ
  def current_user
    @current_user ||= user_from_remember_token
  end

  ##
  # サインイン中かどうかを返す
  # @return [True, False] サインインしていれば_true_
  def signed_in?
    !current_user.nil?
  end

  ##
  # サインアウトを実行する
  def sign_out
    cookies.delete(:remember_token)
    self.current_user = nil
  end

  ##
  # +user+が現在サインイン中かどうかを返す
  # @param [User] 対象となるユーザ
  # @return [True, False] +user+が現在サインイン中なら_true_
  def current_user?(user)
    user == current_user
  end

  ##
  # +user+がサインインしていなければアクセスを拒否する
  def authenticate
    deny_access unless signed_in?
  end

  ##
  # アクセスを拒否する
  def deny_access
    store_location
    redirect_to signin_path, :notice => "Please sign in to access this page"
  end

  ##
  # 元いたページ、またはデフォルトのページにリダイレクトする
  # @param [Path] 元いたページがないときの戻り先
  def redirect_back_or(default)
    redirect_to(session[:return_to] || default)
    clear_return_to
  end

  private

  def user_from_remember_token
    User.authenticate_with_salt(*remember_token)
  end

  def remember_token
    cookies.signed[:remember_token] || [nil, nil]
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def clear_return_to
    session[:return_to] = nil
  end
end
