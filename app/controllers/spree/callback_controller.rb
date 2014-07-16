class Spree::CallbackController < ApplicationController

  protect_from_forgery except: [:push_uri]

  def push_uri

    Spree::Gateway::KlarnaCheckout.find(params[:gw_id]).commit_payment(params[:klarna_order])

    render json:{}
  end

end