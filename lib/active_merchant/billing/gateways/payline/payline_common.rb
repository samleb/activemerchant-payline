require 'active_merchant/billing/iso_4217_currency_codes'
require 'savon'

module ActiveMerchant
  module Billing
    module PaylineCommon
      WEB_API_VERSION = '3'.freeze
      
      IMPL_NAMESPACE = 'http://impl.ws.payline.experian.com'.freeze
      OBJ_NAMESPACE = 'http://obj.ws.payline.experian.com'.freeze
      
      LOG_FILTERED_TAGS = %w( number cvx ).freeze
      
      DATE_FORMAT = "%d/%m/%Y".freeze
      DATETIME_FORMAT = "#{DATE_FORMAT} %H:%M".freeze
      
      SUCCESS_MESSAGES = {
        # Card & Check
        "00000" => "Transaction approved",
        "01001" => "Transaction approved but required a verification by merchant",
        # Wallet
        "02500" => "Operation successful",
        "02501" => "Operation successful but wallet will expire",
        "02517" => "Cannot disable some wallet(s)",
        "02520" => "Cannot enable some wallet(s)",
        # Cancelling & Reauthorizing
        "02616" => "Error while creating the wallet"
      }.freeze
      
      SUCCESS_CODES = SUCCESS_MESSAGES.keys.freeze
      
      ACTION_CODES = {
        :authorization => 100,
        :purchase      => 101, # Authorization + Capture
        :capture       => 201
      }.freeze
      
      PAYMENT_MODES = {
        :direct       => 'CPT',
        :deffered     => 'DIF',
        :installments => 'NX',
        :recurrent    => 'REC'
      }.freeze
      
      # locale => ISO 639-2 code
      LANGUAGE_CODES = {
        'fr' => 'fre',
        'en' => 'eng',
        'es' => 'spa',
        'it' => 'ita',
        'pt' => 'por',
        'de' => 'ger',
        'nl' => 'dut',
        'fi' => 'fin'
      }.freeze
      
      RECURRING_FREQUENCIES = {
        :daily       => 10,
        :weekly      => 20,
        :fortnightly => 30,
        :monthly     => 40,
        :bimonthly   => 50,
        :quarterly   => 60,
        :semiannual  => 70,
        :yearly      => 80,
        :biannual    => 90
      }.freeze
      
      protected
        def request(client, method_name)
          response = client.request :"#{method_name}_request" do
            soap.namespaces[:xmlns] = IMPL_NAMESPACE
            soap.namespaces[:'xmlns:obj'] = OBJ_NAMESPACE
            xml = Builder::XmlMarkup.new
            yield xml
            soap.body = xml.target!
          end
          if response.success?
            response = response.to_hash[:"#{method_name}_response"]
            build_response(response)
          else
            message = (response.soap_fault? ? response.soap_fault : response.http_error).to_s
            Response.new(false, message, {}, { :test => test? })
          end
        end

        def create_savon_client(endpoint)
          Savon.client do
            config.raise_errors = false
            configure_logger(config)
            wsdl.namespace = IMPL_NAMESPACE
            wsdl.endpoint = endpoint
            http.headers["Authorization"] = basic_authentication_header
          end
        end

        def configure_logger(config)
          if logger
            config.logger = logger
            config.logger.filter.push(*LOG_FILTERED_TAGS)
          else
            config.log = false
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
        
        def build_response(response)
          message = message_from(result = response[:result])
          if transaction = response[:transaction]
            transaction_id = transaction[:id] if String === transaction[:id]
          end
          format_response!(response = response.with_indifferent_access)
          Response.new(success?(result), message, response, {
            :authorization => transaction_id,
            :test => test?
          })
        end
      
        def message_from(result)
          message = result[:short_message]
          message << ": " << result[:long_message] unless result[:long_message] == message
          message << " (code #{result[:code]})"
          message
        end
      
        def success?(result)
          SUCCESS_CODES.include?(result[:code])
        end
      
        def contract_number
          options[:contract_number]
        end
      
        def language_code(locale)
          LANGUAGE_CODES[locale.to_s.downcase] if locale
        end
      
        def format_date(time)
          time.strftime(DATETIME_FORMAT)
        end
        
        def format_boolean(boolean, default = false)
          case boolean.nil? ? default : boolean
            when true, 1
              1
            else
              0
          end
        end
        
        def format_response!(response)
          unless response.delete("@xmlns") && response.empty?
            response.each do |key, value|
              if Hash === value
                response[key] = format_response!(value)
              elsif Array === value
                value.map! { |el| format_response!(el) }
              end
            end
          end
        end
      
        def add_version(xml)
          xml.version WEB_API_VERSION
        end
      
        def add_payment(xml, money, currency, action, mode = nil)
          xml.payment do
            xml.obj :action, action_code(action)
            xml.obj :amount, money
            xml.obj :currency, currency
            xml.obj :mode, payment_mode(mode)
            xml.obj :contractNumber, contract_number
          end
        end
      
        def add_order(xml, money, currency, options)
          xml.order do
            xml.obj :ref, options[:order_id]
            xml.obj :amount, money
            xml.obj :currency, currency
            xml.obj :date, format_date(options[:order_date] || Time.now)
          end
        end
        
        def add_buyer(xml, buyer)
          xml.buyer do
            xml.obj :walletId, buyer[:wallet_id] if buyer[:wallet_id].present?
            xml.obj :firstName, buyer[:first_name]
            xml.obj :lastName, buyer[:last_name]
            xml.obj :email, buyer[:email] if buyer[:email].present?
            add_address(xml, buyer[:address]) if buyer[:address].present?
            xml.obj :ip, buyer[:ip] if buyer[:ip].present?
          end
        end
        
        def add_address(xml, address)
        
        end
        
        def action_code(action)
          action = :purchase if action.blank?
          if ACTION_CODES.key?(action)
            ACTION_CODES[action]
          else
            action
          end
        end
        
        def payment_mode(mode)
          mode = :direct if mode.blank?
          if PAYMENT_MODES.key?(mode)
            PAYMENT_MODES[mode]
          else
            mode
          end
        end
    end
  end
end
