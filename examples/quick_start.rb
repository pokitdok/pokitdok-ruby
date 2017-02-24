require 'pokitdok'
require 'dotenv'
Dotenv.load

########################
# make a .env file at the top of your project with
# POKITDOK_CLIENT_ID=your_client_id
# POKITDOK_CLIENT_SECRET=your_secret_id
########################

client_id = ENV["POKITDOK_CLIENT_ID"]
client_secret = ENV["POKITDOK_CLIENT_SECRET"]
pd = PokitDok::PokitDok.new(client_id, client_secret)

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