[![Build Status](https://travis-ci.org/pokitdok/pokitdok-ruby.svg?branch=master)](https://travis-ci.org/pokitdok/pokitdok-ruby)
[![Gem Version](https://badge.fury.io/rb/pokitdok-ruby.svg)](http://badge.fury.io/rb/pokitdok-ruby)
[![Dependency Freshness](https://www.versioneye.com/user/projects/538e498b46c4739edd0000ee/badge.svg)](https://www.versioneye.com/user/projects/538e498b46c4739edd0000ee)


pokitdok-ruby
=============

PokitDok Platform API Client for Ruby

## Resources
* [Read the PokitDok API docs][apidocs]
* [View Source on GitHub][code]
* [Report Issues on GitHub][issues]

[apidocs]: https://platform.pokitdok.com/documentation/v4#/
[code]: https://github.com/PokitDok/pokitdok-ruby
[issues]: https://github.com/PokitDok/pokitdok-ruby/issues

## Installation
    gem install pokitdok-ruby

## Quick Start
```ruby
require 'pokitdok'
pd = PokitDok::PokitDok.new("your_client_id", "your_client_secret")

# Retrieve provider information by NPI
pd.providers(npi: '1467560003')

# Search providers by name (individuals)
pd.providers(first_name: 'JEROME', last_name: 'AYA-AY')

# Search providers by name (organizations)
pd.providers(name: 'Qliance')

# Search providers by location and/or specialty
pd.providers(zipcode: '29307', radius: '10mi')
pd.providers(zipcode: '29307', radius: '10mi', specialty: 'RHEUMATOLOGY')

# Eligibility
@eligibility_query = {
  member: {
      birth_date: '1970-01-01',
      first_name: 'Jane',
      last_name: 'Doe',
      id: 'W000000000'
  },
  provider: {
      first_name: 'JEROME',
      last_name: 'AYA-AY',
      npi: '1467560003'
  },
  service_types: ['health_benefit_plan_coverage'],
  trading_partner_id: 'MOCKPAYER'
}

pd.eligibility @eligibility_query

# Claim
@claim = {
  transaction_code: 'chargeable',
  trading_partner_id: 'MOCKPAYER',
  billing_provider: {
    taxonomy_code: '207Q00000X',
    first_name: 'Jerome',
    last_name: 'Aya-Ay',
    npi: '1467560003',
    address: {
      address_lines: ['8311 WARREN H ABERNATHY HWY'],
      city: 'SPARTANBURG',
      state: 'SC',
      zipcode: '29301'
    },
    tax_id: '123456789'
  },
  subscriber: {
    first_name: 'Jane',
    last_name: 'Doe',
    member_id: 'W000000000',
    address: {
      address_lines: ['123 N MAIN ST'],
      city: 'SPARTANBURG',
      state: 'SC',
      zipcode: '29301'
    },
    birth_date: '1970-01-01',
    gender: 'female'
  },
  claim: {
    total_charge_amount: 60.0,
    service_lines: [
      {
        procedure_code: '99213',
        charge_amount: 60.0,
        unit_count: 1.0,
        diagnosis_codes: ['487.1'],
        service_date: '2014-06-01'
      }
    ]
  }
}

pd.claims @claim

# Retrieve an index of activities
pd.activities 

# Check on a specific activity
pd.activities(activity_id: '5362b5a064da150ef6f2526c')

# Check on a batch of activities
pd.activities(parent_id: '537cd4b240b35755f5128d5c')

# Upload an EDI file
pd.files('trading_partner_id', 'path/to/a_file.edi')

# Get cash prices
pd.cash_prices(cpt_code: '87799', zip_code: '75201')

# Get insurance prices
pd.insurance_prices(cpt_code: '87799', zip_code: '29403')
              
```

## Check SSL protocol and cipher
```ruby
pd.request('/ssl/')
```

## Supported Ruby Versions
This library aims to support and is tested against these Ruby versions, 
using travis-ci:

* 2.2.3
* 2.1.1
* 2.0.0
* 1.9.3
* JRuby in 1.9 mode

You may have luck with other interpreters - let us know how it goes.

## Development/Debugging

##### Prerequisite: Make sure to have the RubyMine plugin installed with IntelliJ.

#### Steps to getting setup in the IntelliJ IDE:
1. Fork and/or clone the `pokitdok-ruby` github repository onto your local machine.
2. Open IntelliJ IDE.
3. Select `File > New > Project From Existing Sources` and select the directory of the cloned `pokitdok-ruby` project.
4. In the pop-up GUI select `Create project from existing sources` and continue selecting next/finish with the default settings.
5. Next you want to make sure ruby has selected the correct ruby SDK. It is recommended to use rvm for ruby version management.
  * Select `File > Project Structure`. Then under the Project -> SDK settings select the ruby version you wish to use with the project (i.e.- `RVM: ruby-1.9.3-p551 [global]`).
6. You will probably be prompted to install the project dependencies with bundler which you should do.
7. Now to debug tests you need to create a `run configuration`.
  * Select `Run > Edit Configurations`. 
  * We use `rake` to run our project tasks. So select the `+` button and add a new `Rake` configuration.
  * A few properties you need to set: 
    * Task Name: `spec`
    * Ruby SDK -> Use other SDK and 'rake' gem: `Whichever ruby version you chose in step 5`
    * Bundler Tab: Check the box labeled `Run the script in the context of the bundle (bundle exec)`
8. You can now run/debug the project tests in the IntelliJ IDE.
  * NOTE: Currently the tests will not finish executing though all are completed. This is a known issue with RubyMine.

NOTE: If you would just like to run the test framework outside of the IDE make sure to have all the dependencies installed via bundle in the project directory then run the following command: `bundle exec rake spec`.

## License
Copyright (c) 2014 PokitDok Inc. See [LICENSE][] for details.

[license]: LICENSE.txt
