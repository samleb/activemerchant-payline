module ActiveMerchant
  module Billing
    module PaylineDirectAPI
      CARD_BRAND_CODES = Hash.new('CB').update(
        'visa'             => 'VISA',
        'master'           => 'MASTERCARD',
        'american_express' => 'AMEX',
        'diners_club'      => 'DINERS',
        'jcb'              => 'JCB',
        'switch'           => 'SWITCH',
        'maestro'          => 'MAESTRO'
      ).freeze
      
      EXPIRATION_DATE_FORMAT = "%.2d%.2d".freeze
      
      def do_authorization(money, credit_card, options = {})
        requires!(options, :order_id)
        currency = currency_code(options[:currency])
        direct_api_request :do_authorization do |xml|
          add_payment(xml, money, currency, :authorization, options[:mode])
          add_credit_card(xml, credit_card)
          add_order(xml, money, currency, options)
        end
      end
      alias_method :authorize, :do_authorization

      def do_capture(money, authorization, options = {})
        direct_api_request :do_capture do |xml|
          xml.transactionID authorization
          add_payment(xml, money, currency_code(options[:currency]), :capture, options[:mode])
        end
      end
      alias_method :capture, :do_capture
      
      def do_recurrent_wallet_payment(money, wallet_id, options = {})
        currency = currency_code(options[:currency])
        direct_api_request :do_recurrent_wallet_payment do |xml|
          add_version(xml)
          xml.walletId wallet_id
          xml.scheduledDate format_date(options[:scheduled_date] || Time.now)
          add_payment(xml, money, currency, :capture, :recurrent)
          add_order(xml, money, currency, options)
          xml.recurring do
            xml.obj :amount, options[:recurring_amount]
            xml.obj :billingLeft, options[:terms]
            xml.obj :billingCycle, PaylineCommon::RECURRING_FREQUENCIES[options[:frequency]]
          end
        end
      end
      
      def get_recurrent_payment_responses(payment_record_id)
        response = get_payment_record(payment_record_id)
        responses = response.params[:billing_record_list][:billing_record]
        responses.collect { |r| build_response(r) if r[:result] }.compact
      end
      
      def get_payment_record(payment_record_id)
        payment_record_request :get, payment_record_id
      end
      
      def disable_payment_record(payment_record_id)
        payment_record_request :disable, payment_record_id
      end
      
      protected
        def direct_api_request(method_name, &block)
          request(direct_api_savon_client, method_name, &block)
        end
        
        def direct_api_savon_client
          @direct_api_savon_client ||= create_savon_client(test? ? test_url : live_url)
        end
        
        def add_credit_card(xml, card)
          xml.card do
            xml.obj :number, card.number
            xml.obj :type, CARD_BRAND_CODES[card.brand]
            xml.obj :expirationDate, expiration_date(card.month, card.year)
            xml.obj :cvx, card.verification_value
          end
        end
        
        def expiration_date(month, year)
          EXPIRATION_DATE_FORMAT % [month, year.to_s[-2..-1]]
        end
        
        def payment_record_request(method_name, payment_record_id)
          direct_api_request :"#{method_name}_payment_record" do |xml|
            xml.contractNumber contract_number
            xml.paymentRecordId payment_record_id
          end
        end
    end
  end
end
