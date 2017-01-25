class Api::ContactsController < ApplicationController

  def index
    @contacts = Contact.all
    if params[:customer_id]
      @contacts = @contacts.where(customer_id: params[:customer_id])
    end
  end

end