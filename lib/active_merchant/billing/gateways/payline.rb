require 'active_merchant/billing/gateways/payline/payline_common'
require 'active_merchant/billing/gateways/payline/payline_direct_api'
require 'active_merchant/billing/gateways/payline/payline_web_api'

module ActiveMerchant
  module Billing
    class PaylineGateway < Gateway
      include PaylineCommon
      include PaylineDirectAPI
      include PaylineWebAPI
      
      API_VERSION = '4.24'.freeze
      
      self.display_name = 'Payline'
      self.homepage_url = 'http://www.payline.com/'
      
      self.default_currency = 'EUR'
      self.money_format = :cents
      self.supported_cardtypes = [:visa, :master, :american_express, :diners_club, :jcb]
      
      class_attribute :web_live_url, :web_test_url, :instance_writer => false
      
      self.live_url = 'https://services.payline.com/V4/services/DirectPaymentAPI'.freeze
      self.test_url = 'https://homologation.payline.com/V4/services/DirectPaymentAPI'.freeze
      
      self.web_live_url = 'https://services.payline.com/V4/services/WebPaymentAPI/'.freeze
      self.web_test_url = 'https://homologation.payline.com/V4/services/WebPaymentAPI/'.freeze
      
      include ISO4217CurrencyCodes
      
      def initialize(options = {})
        # FIXME: should not be blank!
        requires!(options, :merchant_id, :merchant_access_key, :contract_number)
        @options = options
      end
    end
    
    Payline = ActiveSupport::Deprecation::DeprecatedConstantProxy.new('ActiveMerchant::Billing::Payline', PaylineGateway)
  end
end
