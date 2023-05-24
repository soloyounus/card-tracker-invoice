class SessionsController < ApplicationController
  PASSWORD = '2c932a0c'

  def new
  end

  def create
    if params[:password] == PASSWORD
      session[:logged_in] = true
      redirect_to controller: :invoices, action: :new
      return
    else
      flash[:error] = "Incorrect password"
      redirect_to action: :new
    end
  end
end
