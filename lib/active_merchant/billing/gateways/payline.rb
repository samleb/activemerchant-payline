require 'active_merchant/billing/iso_4217_currency_codes'
require 'savon'

module ActiveMerchant
  module Billing
    class Payline < Gateway
      API_VERSION = '4.24'.freeze
      
      self.display_name = 'Payline DirectPayment'
      self.homepage_url = 'http://www.payline.com/'
      
      self.default_currency = 'EUR'
      self.money_format = :cents
      self.supported_cardtypes = [:visa, :master, :american_express, :diners_club, :jcb]
      
      self.live_url = 'https://services.payline.com/V4/services/DirectPaymentAPI'.freeze
      self.test_url = 'https://homologation.payline.com/V4/services/DirectPaymentAPI'.freeze
      
      include ISO4217CurrencyCodes
      
      IMPL_NAMESPACE = 'http://impl.ws.payline.experian.com'.freeze
      OBJ_NAMESPACE = 'http://obj.ws.payline.experian.com'.freeze
      
      DATE_FORMAT = "%d/%m/%Y %H:%M".freeze
      
      SUCCESS_CODE = '00000'.freeze

      ACTION_CODES = {
        :authorization => 100,
        :full_capture  => 201
      }.freeze
      
      PAYMENT_MODES = {
        :direct       => 'CPT',
        :deffered     => 'DIF',
        :installments => 'NX',
        :recurrent    => 'REC'
      }.freeze
      
      def initialize(options = {})
        requires!(options, :merchant_id, :merchant_access_key, :contract_number)
        @options = options
      end
      
      def authorize(money, credit_card, options = {})
        requires!(options, :order_id)
        currency = currency_code(options[:currency])
        request :do_authorization do |xml|
          add_payment(xml, money, currency, :authorization)
          add_credit_card(xml, credit_card)
          add_order(xml, money, currency, options)
        end
      end

      def capture(money, authorization, options = {})
        request :do_capture do |xml|
          xml.transactionID authorization
          add_payment(xml, money, currency_code(options[:currency]), :full_capture)
        end
      end

      protected
        def request(method_name)
          response = savon_client.request(:"#{method_name}_request") do
            soap.namespaces[:xmlns] = IMPL_NAMESPACE
            soap.namespaces[:'xmlns:obj'] = OBJ_NAMESPACE
            xml = Builder::XmlMarkup.new
            yield xml
            soap.body = xml.target!
          end
          if response.success?
            response = response.to_hash[:"#{method_name}_response"]
            message = message_from(response[:result])
            transaction_id = response[:transaction][:id] if String === response[:transaction][:id]
            Response.new(success?(response), message, response, {
              :authorization => transaction_id,
              :test => test?
            })
          else
            fault = response.to_hash[:fault]
            message = "#{fault[:faultcode]} #{fault[:faultstring]}"
            Response.new(false, message, {}, { :test => test? })
          end
        end

        def savon_client
          @savon_client ||= Savon.client do
            config.raise_errors = false
            wsdl.namespace = IMPL_NAMESPACE
            wsdl.endpoint = test? ? test_url : live_url
            http.headers["Authorization"] = basic_authentication_header
          end
        end

        def basic_authentication_header
          string = [options[:merchant_id], options[:merchant_access_key]].join(':')
          "Basic #{strict_encode64(string)}"
        end

        # Base64.strict_encode64 is only available in 1.9 stdlib
        def strict_encode64(string)
          [string].pack('m0')
        end
        
        def add_payment(xml, money, currency, action)
          xml.payment do
            xml.obj :action, ACTION_CODES[action]
            xml.obj :amount, money
            xml.obj :currency, currency
            xml.obj :mode, PAYMENT_MODES[:direct]
            xml.obj :contractNumber, options[:contract_number]
          end
        end
        
        def add_credit_card(xml, card)
          xml.card do
            xml.obj :number, card.number
            xml.obj :type, 'CB' # FIXME
            xml.obj :expirationDate, card.expiry_date.expiration.strftime("%m%y")
            xml.obj :cvx, card.verification_value
          end
        end
        
        def add_order(xml, money, currency, options)
          xml.order do
            xml.obj :ref, options[:order_id]
            xml.obj :amount, money
            xml.obj :currency, currency
            xml.obj :date, (options[:date] || Time.now).strftime(DATE_FORMAT)
          end
        end
        
        def message_from(result)
          "#{result[:short_message]}: #{result[:long_message]} (code #{result[:code]})}"
        end
        
        def success?(response)
          response[:result][:code] == SUCCESS_CODE
        end
    end
  end
end
