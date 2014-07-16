Spree::CheckoutController.class_eval do

  def confirmation
    @confirmation_html = Spree::Gateway::KlarnaCheckout.find(params[:gw_id]).confirmation_html(params[:klarna_order])
  end

end
