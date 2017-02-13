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
        refute_nil(response["meta"].keys, msg="the response[meta] section is empty")
        refute_nil(response["data"].keys, msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"
      end
    end
    describe 'Error Test: Missing Trading Partner ID' do
      it 'make a call to eligibility without a Trading partner' do
        @eligibility_query_2 = {
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
        }
        response = @@pokitdok.eligibility @eligibility_query_2
        refute_nil(response["meta"].keys, msg="the response[meta] section is empty")
        refute_nil(response["data"].keys, msg="the response[data] section is empty")
        assert response["data"]["errors"]["query"].to_s.include? "Unable to find configuration for trading_partner_id: None, transaction_set_name: eligibility"
        assert @@pokitdok.status_code == 400, "Status Code assertion failure. Tested for 400, Observed status code: #{@@pokitdok.status_code}"
      end
    end
    describe 'Validation Error Test: Malformed Request' do
      it 'make a call to eligibility with bad data' do
        @bad_request = "bad request"
        response = @@pokitdok.eligibility @bad_request
        refute_nil(response["meta"].keys, msg="the response[meta] section is empty")
        refute_nil(response["data"].keys, msg="the response[data] section is empty")
        assert response["data"]["errors"]["validation"].to_s.include? "This endpoint only accepts JSON requests of <type 'dict'>. Request provided was of <type 'unicode'>."
        assert @@pokitdok.status_code == 422, "Status Code assertion failure. Tested for 422, Observed status code: #{@@pokitdok.status_code}"
      end
    end
    describe 'Validation Error Test: Malformed Request' do
      it 'make a call to eligibility with bad data' do
        @bad_request = {
            member: {
                birth_date: '1970-01-01',
                first_name: 'Jane',
                last_name: 'Doe',
                id: '1'
            },
            trading_partner_id: 'MOCKPAYER'
        }
        response = @@pokitdok.eligibility @bad_request
        refute_nil(response["meta"].keys, msg="the response[meta] section is empty")
        refute_nil(response["data"].keys, msg="the response[data] section is empty")
        assert response["data"]["errors"]["validation"]["member"]["id"].to_s.include? "String value is too short."
        assert @@pokitdok.status_code == 422, "Status Code assertion failure. Tested for 422, Observed status code: #{@@pokitdok.status_code}"
      end
    end
    describe 'Validation Error Test: Malformed Request' do
      it 'make a call to eligibility with bad data' do
        @bad_request = {
            member: {
                birth_date: '1970-01-01',
                first_name: 'Jane',
                last_name: 'Doe',
                id: '100000000000'
            },
            provider: {
                first_name: 'JEROME',
                last_name: 'AYA-AY',
                npi: '2'
            },
            trading_partner_id: 'MOCKPAYER'
        }
        response = @@pokitdok.eligibility @bad_request
        refute_nil(response["meta"].keys, msg="the response[meta] section is empty")
        refute_nil(response["data"].keys, msg="the response[data] section is empty")
        assert response["data"]["errors"]["validation"]["provider"]["npi"].to_s.include? "String value is too short."
        assert @@pokitdok.status_code == 422, "Status Code assertion failure. Tested for 422, Observed status code: #{@@pokitdok.status_code}"
      end
    end
    describe 'Live Eligibility Test via the direct POST method' do
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
        response = @@pokitdok.post('eligibility/', @eligibility_query)
        refute_nil(response["meta"].keys, msg="the response[meta] section is empty")
        refute_nil(response["data"].keys, msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"
      end
    end
    describe 'Live test of PUT and DELETE via the claims and activities endpoints' do
      it 'should make a real eligibility call' do
        @test_claim = {
            transaction_code: "chargeable",
            trading_partner_id: "MOCKPAYER",
            billing_provider: {
                taxonomy_code: "207Q00000X",
                first_name: "Jerome",
                last_name: "Aya-Ay",
                npi: "1467560003",
                address: {
                    address_lines: [
                        "8311 WARREN H ABERNATHY HWY"
                    ],
                    city: "SPARTANBURG",
                    state: "SC",
                    zipcode: "29301"
                },
                tax_id: "123456789"
            },
            subscriber: {
                first_name: "Jane",
                last_name: "Doe",
                member_id: "W000000000",
                address: {
                    address_lines: ["123 N MAIN ST"],
                    city: "SPARTANBURG",
                    state: "SC",
                    zipcode: "29301"
                },
                birth_date: "1970-01-25",
                gender: "female"
            },
            claim: {
                total_charge_amount: 60.0,
                service_lines: [
                    {
                        procedure_code: "99213",
                        charge_amount: 60.0,
                        unit_count: 1.0,
                        diagnosis_codes: [
                            "J10.1"
                        ],
                        service_date: "2016-01-25"
                    }
                ]
            }
        }
        # assert success of the claim post
        claim_response = @@pokitdok.claims(@test_claim)
        refute_nil(claim_response["meta"].keys, msg="the response[meta] section is empty")
        refute_nil(claim_response["data"].keys, msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"
        activity_id = claim_response["meta"]["activity_id"]
        activity_url = "/activities/#{activity_id}"

        # check to see if the claim has started processing yet
        get_response = @@pokitdok.get(url, data={})
        assert refute_nil(get_response["data"]["history"], msg="the response[data][history] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"
        history = get_response["data"]["history"]
        if history.length != 1
          # this means that the claim is been picked up and is processing within the internal pokitdok system
          # we aim to test out the put functionality by deleting the claim, so we need to resubmit
          claim_response = @@pokitdok.claims(@test_claim)
          refute_nil(claim_response["meta"].keys, msg="the response[meta] section is empty")
          refute_nil(claim_response["data"].keys, msg="the response[data] section is empty")
          assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"
          activity_id = claim_response["meta"]["activity_id"]
          activity_url = "/activities/#{activity_id}"
        end
        # exercise the PUT functionality to remove a claim
        put_data = @@pokitdok.put(url, data={transition: "cancel"})

      end
    end
  end
end
