class Spree::BillingIntegration::PaypalWebsiteStandard < Spree::BillingIntegration

  # attr_accessible :preferred_account_email, :preferred_ipn_notify_host, :preferred_success_url, 
  #  :preferred_paypal_url, :preferred_encryption, :preferred_certificate_id, 
  #  :preferred_currency, :preferred_language,
  #  :preferred_server, :preferred_test_mode

  require 'rbconfig'

  preference :account_email, :string
  preference :ipn_notify_host, :string
  preference :ipn_secret, :string
  preference :success_url, :string
  preference :paypal_url, :string, :default => 'https://www.paypal.com/cgi-bin/webscr'
  preference :sandbox_url, :string, :default => 'https://www.sandbox.paypal.com/cgi-bin/webscr'
  preference :encryption, :boolean, :default => false
  preference :certificate_id, :string
  preference :currency, :string, :default => "EUR"
  preference :language, :string, :default => "en"
  preference :page_style, :string
  preference :populate_address, :boolean, :default => true

  def payment_profiles_supported?
    false
  end

end
