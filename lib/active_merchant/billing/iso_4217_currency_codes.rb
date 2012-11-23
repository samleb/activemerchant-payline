module ActiveMerchant
  module Billing
    module ISO4217CurrencyCodes
      CURRENCY_CODES = { 
        "AUD" => '036',
        "CAD" => '124',
        "CZK" => '203',
        "DKK" => '208',
        "HKD" => '344',
        "ICK" => '352',
        "JPY" => '392',
        "NOK" => '578',
        "SGD" => '702',
        "SEK" => '752',
        "CHF" => '756',
        "GBP" => '826',
        "USD" => '840',
        "EUR" => '978'
      }.freeze
      
      protected
        def currency_code(currency)
          currency = if currency.present?
            currency.to_s.upcase
          else
            default_currency
          end
          CURRENCY_CODES[currency]
        end
    end
  end
end