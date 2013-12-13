module Spree
  class PaymentNotificationsController < BaseController
    protect_from_forgery :except => [:create]
    skip_before_filter :restriction_access
    
    def create
      payment_method = Spree::BillingIntegration::PaypalWebsiteStandard.first
      if(payment_method.preferred_encryption && (params[:secret] != payment_method.preferred_ipn_secret))
        logger.info "PayPal_Website_Standard: attempt to send an IPN with invalid secret"
        raise Exception
      end

      case params[:txn_type]
      when "recurring_payment"
        # TODO
      when "recurring_payment_expired"
      when "recurring_payment_failed"
      when "recurring_payment_profile_created"
      when "recurring_payment_profile_canceled"
      when "recurring_payment_skipped"
      when "recurring_payment_suspended"
      when "recurring_payment_suspended_due_to_max_failed_payment"
      when "cart"
        @order = Spree::Order.find_by_number(params[:invoice])
        if @order.nil?
          logger.info "PayPal IPN processing error: Order #{params[:invoice]} not found."
          raise Exception
        end

        Spree::PaymentNotification.create!(
          :params => params,
          :order_id => @order.id,
          :status => params[:payment_status],
          :transaction_id => params[:txn_id])
        
        # load the payment object; should have been created when order transitioned to "payment"
        existing_payment = @order.payments.find_by_identifier(params[:custom])
        if existing_payment.nil?
          logger.info "PayPal IPN processing error: Payment with identifier #{params[:custom]} not found for order #{params[:invoice]}."
          raise Exception
        end

        # rmleitao:
        # Create payment for this order
        # Even though Spree automatically creates a Payment object once the user reaches the payment order state
        # we should create a new Payment that reflects exactly what Paypal IPN is telling us that was paid.
        # We need a Payment object in the state Checkout, so that the Order state machine can transition to completed
        @payment = Spree::Payment.new
        @payment.amount = params[:mc_gross]
        @payment.payment_method = existing_payment.payment_method

        @order.payments << @payment

        @payment.payment_method = Spree::Order.paypal_payment_method
        @payment.started_processing!

        # rmleitao:
        # Check the PayPal IPN status. If complete, complete the payment.
        # All other states should render the payment as failed
        case params[:payment_status]
        when "Completed"
          # The Payment has been captured, and if IPN says so, the money is in the PayPal account.
          # So it's safe to say the Payment can be "completed"
          @payment.complete!
        else
          @payment.failure!
        end
        @order.save!

        Order.transaction do
          order = @order
          until @order.state == "complete"
            if @order.next!
              @order.update!
              state_callback(:after)
            end
          end
        end

      end
      
      render :nothing => true
    end
    
    private

    # those methods are copy-pasted from CheckoutController
    # we cannot inherit from that class unless we want to skip_before_filter
    # half of calls in SpreeBase module
    def state_callback(before_or_after = :before)
      method_name = :"#{before_or_after}_#{@order.state}"
      send(method_name) if respond_to?(method_name, true)
    end
    
    def before_address
      @order.bill_address ||= Address.new(:country => default_country)
      @order.ship_address ||= Address.new(:country => default_country)
    end
    
    def before_delivery
      @order.shipping_method ||= (@order.rate_hash.first && @order.rate_hash.first[:shipping_method])
    end
    
    def before_payment
      current_order.payments.destroy_all if request.put?
    end
    
		#This isn't working here in payment_nofitications_controller since IPN will run on a different session
    def after_complete
      session[:order_id] = nil
    end
    
    def default_country
      Country.find Spree::BillingIntegration::PaypalWebsiteStandard::Config.default_country_id
    end
    
  end
end