module ActiveMerchant
  module Billing
    module PaylineWebAPI
      SSL = 'SSL'.freeze
      
      def do_web_payment(money, options = {})
        currency = currency_code(options[:currency])
        web_api_request :do_web_payment do |xml|
          add_version(xml)
          add_payment(xml, money, currency, options[:action], options[:mode])
          add_order(xml, money, currency, options)
          add_buyer(xml, options)
          add_web_params(xml, options)
        end
      end
      alias_method :setup_purchase, :do_web_payment
      
      # :wallet_id [String] alpha-numeric 50 chars max
      # :locale [String, Symbol] ISO 639-1 locale code
      # :return_url (*)
      # :cancel_return_url (*)
      # :notify_url
      # :custom_payment_page_code
      # :data [Hash] hash of custom data
      def create_web_wallet(options = {})
        web_wallet_request :create, options do |xml|
          xml.selectedContractList do
            xml.obj :selectedContract, contract_number
          end
          add_buyer(xml, options)
          xml.updatePersonalDetails format_boolean(options[:update_personal_details])
          xml.privateDataList do
            options[:data].to_hash.each do |key, value|
              xml.obj :key, key
              xml.obj :value, value
            end
          end if options[:data].present?
        end
      end

      def update_web_wallet(wallet_id, options = {})
        web_wallet_request :update, options do |xml|
          xml.walletId wallet_id
          xml.updatePaymentDetails format_boolean(options[:update_payment_details], true)
          xml.updatePersonalDetails format_boolean(options[:update_personal_details])
          xml.updateOwnerDetails format_boolean(options[:update_owner_details])
        end
      end

      def get_web_wallet(token)
        web_api_request :get_web_wallet do |xml|
          add_version(xml)
          xml.token token
        end
      end

      protected
        def web_api_request(method_name, &block)
          request(web_api_savon_client, method_name, &block)
        end
        
        def web_api_savon_client
          @web_api_savon_client ||= create_savon_client(test? ? web_test_url : web_live_url)
        end
        
        def web_wallet_request(method_name, options)
          web_api_request :"#{method_name}_web_wallet" do |xml|
            xml.contractNumber contract_number
            yield xml
            add_web_params(xml, options)
          end
        end
        
        def add_web_params(xml, options)
          xml.languageCode language_code(options[:locale])
          xml.securityMode SSL
          xml.returnURL options[:return_url]
          xml.cancelURL options[:cancel_return_url]
          xml.notificationURL options[:notify_url]
          xml.customPaymentPageCode options[:custom_payment_page_code]
        end
    end
  end
end