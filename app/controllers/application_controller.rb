# @todo rework auth & "users"
class ApplicationController < ActionController::Base
  before_action :require_login

  private

  def require_login
    # anon - confined to session controller
    if !session[:logged_in] && controller_name != 'sessions'
      redirect_to controller: :sessions, action: :new
    end

    # logged in - confined to invoices or reports controller
    if session[:logged_in]
      unless (controller_name === 'invoices' || controller_name === 'reports')
        redirect_to controller: :invoices, action: :new
      end
    end
  end
end
