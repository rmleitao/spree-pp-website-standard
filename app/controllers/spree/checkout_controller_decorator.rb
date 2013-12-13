# commented-out as this is too invasive at the moment 
# (assumes paypal is the only payment method available in your store)

Spree::CheckoutController.class_eval do
  def edit
    puts "NINJA IN DECORATED CONTROLLER!!"
    if ((@order.state == "payment") && @order.valid?)
      puts "valid, processing"
      if @order.payable_via_paypal?
        puts "payable via paypal, adding payment"
        payment = Spree::Payment.new
        payment.amount = @order.total
        payment.payment_method = Spree::Order.paypal_payment_method
        @order.payments << payment
        payment.started_processing
        # render(:partial => 'checkout/paypal_checkout')
      end
    end
  end
end
