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

This version of pokitdok-ruby supports, and defaults to using, the new
PokitDok v4 API. If you'd like to continue using the previous v3 API,
you can pass a third parameter to PokitDok::Pokitdok.new, like this:

```
@pd = PokitDok::PokitDok.new('my_client_id', 'my_client_secret', 'v3')
```

## Supported Ruby Versions
This library aims to support and is tested against these Ruby versions, 
using travis-ci:

* 2.2.3
* 2.1.1
* 2.0.0
* 1.9.3
* JRuby in 1.9 mode
* Rubinius 2

You may have luck with other interpreters - let us know how it goes.

## License
Copyright (c) 2014 PokitDok Inc. See [LICENSE][] for details.

[license]: LICENSE.txt
