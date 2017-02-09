# encoding: UTF-8

require 'spec_helper'
require 'dotenv'
Dotenv.load


CLIENT_ID = ENV["POKITDOK_CLIENT_ID"]
CLIENT_SECRET = ENV["POKITDOK_CLIENT_SECRET"]
SCHEDULE_AUTH_CODE = 'KmCCkuYkSmPEf7AxaCIUApX1pUFedJx9CrDWPMD8'
BASE_URL = 'https://platform.pokitdok.com/v4/api'
MATCH_NETWORK_LOCATION = /(.*\.)?pokitdok\.com/
MATCH_OAUTH2_PATH = /[\/]oauth2[\/]token/
TEST_REQUEST_PATH = '/endpoint'

class PokitDokTest < MiniTest::Test
  @@pokitdok = nil
  @@current_request = nil

  describe PokitDok do

    before do
      if @@pokitdok.nil?
        @@pokitdok = PokitDok::PokitDok.new(CLIENT_ID, CLIENT_SECRET)
      end
    end

    describe 'Test token reuse' do
      it 'should work with existing token' do
        pokitdok_for_token = PokitDok::PokitDok.new(CLIENT_ID, CLIENT_SECRET)
        first_token = pokitdok_for_token.token

        pokitdok_with_old_token = PokitDok::PokitDok.new(CLIENT_ID, CLIENT_SECRET, nil, nil, nil, nil, nil, token=first_token)
        second_token = pokitdok_with_old_token.token

        assert first_token == second_token
        results = pokitdok_with_old_token.activities
        refute_nil(results)

        pokitdok_for_new_token = PokitDok::PokitDok.new(CLIENT_ID, CLIENT_SECRET)
        third_token = pokitdok_for_new_token.token
        assert (first_token != third_token) && (second_token != third_token)
      end
    end

    describe 'Test Connection' do
      it 'should instantiate the api_client' do
        refute_nil(@@pokitdok)
        assert @@pokitdok.user_agent.include? "pokitdok-ruby#"
      end
    end

    describe 'Live Eligibility Test' do
      it 'should make a real eligibility call' do
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
        response = @@pokitdok.eligibility @eligibility_query
        assert response.keys == ["meta", "data"]
        refute_nil(response["meta"].keys)
        refute_nil(response["data"].keys)
        assert response["data"]["client_id"] == CLIENT_ID
      end
    end
  end
end
