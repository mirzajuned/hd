class ErrorsController < ApplicationController
  def not_found
    render :status => 404
  end

  # def unacceptable #*******************************************not working**************************
  #  render :status => 422
  # end

  def internal_error
    render :status => 500
  end

  def show
    if params[:id] == "empty_store"
      @message = "There is no store present in your Hospital, please add the store or contact your Admin"
    end
  end
end
