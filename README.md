# ActiveMerchant Payline

ActiveMerchant implementation of the [Payline] [1] Gateway.

## Introduction

### Disclaimer

This project is a work in progress and is still in alpha stage.
All method names and arguments are subject to changes.

**DO NOT USE IT IN PRODUCTION** unless you fully understand the implications.

### Current support

#### Direct Payment API

* doAuthorization (`authorize`)
* doCapture (`capture`)
* doRecurrentWalletPayment
* getPaymentRecord
* disablePaymentRecord

#### Web Payment API

* doWebPayment (`setup_purchase`)
* createWebWallet
* getWebWallet
* updateWebWallet

### TODO

A beta release will be considered when this list is complete:

* Add support for missing Direct Payment API methods
* Add support for missing Web Payment API methods
* Implement unit tests
* Implement remote tests using [Payline Homologation] [2]

## Installation

Add this line to your application's Gemfile:

    gem 'activemerchant-payline'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activemerchant-payline

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[1]: http://www.payline.com/
[2]: https://homologation-admin.payline.com/
