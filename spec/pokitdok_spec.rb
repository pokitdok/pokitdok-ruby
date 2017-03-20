# encoding: UTF-8

require 'spec_helper'
require 'dotenv'
Dotenv.load

CLIENT_ID = ENV["POKITDOK_CLIENT_ID"]
CLIENT_SECRET = ENV["POKITDOK_CLIENT_SECRET"]

class PokitDokTest < MiniTest::Test
  @@pokitdok = nil
  @@current_request = nil
  @identity_request = {
      prefix: "Mr.",
      first_name: "Oscar",
      middle_name: "Harold",
      last_name: "Whitmire",
      suffix: "IV",
      birth_date: "2000-05-01",
      gender: "male",
      email: "oscar@pokitdok.com",
      phone: "555-555-5555",
      secondary_phone: "333-333-4444",
      address: {
          address_lines: ["1400 Anyhoo Avenue"],
          city: "Springfield",
          state: "IL",
          zipcode: "90210"
      },
      identifiers: [
          {
              provider_uuid: "1917f12b-fb6a-4016-93bc-adeb83204c83",
              system_uuid: "967d207f-b024-41cc-8cac-89575a1f6fef",
              value: "W90100-IG-88",
              location: [-121.93831, 37.53901]
          }
      ]
  }

  describe PokitDok do

    before do
      if @@pokitdok.nil?
        @@pokitdok = PokitDok::PokitDok.new(CLIENT_ID, CLIENT_SECRET)
      end
    end
    #
    # ******************************
    # client set up tests
    # ******************************
    #
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

    #
    # ******************************
    # error tests
    # ******************************
    #
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
        assert @@pokitdok.status_code == 400, "Status Code assertion failure. Tested for 400, Observed status code: #{@@pokitdok.status_code}"
      end
    end
    describe 'Validation Error Test: Malformed Request' do
      it 'make a call to eligibility with bad data' do
        @bad_request = "bad request"
        response = @@pokitdok.eligibility @bad_request
        refute_nil(response["meta"].keys, msg="the response[meta] section is empty")
        refute_nil(response["data"].keys, msg="the response[data] section is empty")
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
        assert @@pokitdok.status_code == 422, "Status Code assertion failure. Tested for 422, Observed status code: #{@@pokitdok.status_code}"
      end
    end
    #
    # ******************************
    # get/post/put tests
    # ******************************
    #
    describe 'test the POST method' do
      it 'should make a real eligibility via the POST method' do
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
    describe 'Live test of PUT, DELETE, CLAIMS, ACTIVITIES' do
      it 'Exercise the workflow of submitting a and deleting a claim' do
        # this claim body represents the minimal amount of data needed to submit a claim via the claims endpoint
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
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200 on use of claims endpoint, Observed status code: #{@@pokitdok.status_code}"

        # use the activities endpoint via a GET to analyze the current status of this claim
        activity_id = claim_response["meta"]["activity_id"]
        activity_url = "/activities/#{activity_id}"
        get_response = @@pokitdok.get(activity_url, data={})
        refute_nil(get_response["data"]["history"], msg="the response[data][history] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200 on the first get to activities, Observed status code: #{@@pokitdok.status_code}"

        # look in the history to see if it has transitioned from state "init" to "canceled"
        history = get_response["data"]["history"]
        if history.length != 1
          # this means that the claim is been picked up and is processing within the internal pokitdok system
          # we aim to test out the put functionality by deleting the claim,
          # so we need to resubmit a claim to get one that is going to stay in the INIT stage
          claim_response = @@pokitdok.claims(@test_claim)
          refute_nil(claim_response["meta"].keys, msg="the response[meta] section is empty")
          refute_nil(claim_response["data"].keys, msg="the response[data] section is empty")
          assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200 on the second use of claims endpoint, Observed status code: #{@@pokitdok.status_code}"
          activity_id = claim_response["meta"]["activity_id"]
          activity_url = "/activities/#{activity_id}"
        end

        # exercise the PUT functionality to delete the claim from its INIT status
        put_data = @@pokitdok.put(activity_url, data={transition: "cancel"})
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200 on put to cancel the activity, Observed status code: #{@@pokitdok.status_code}"
        refute_nil(put_data, msg="the respones body is empty")
        refute_nil(put_data["data"], msg="the responesbody[data] is empty")
        assert put_data["data"].kind_of?(Hash), "Error grabbing the activity data; try running the test suite again. Full response: #{put_data}"

        # look in the history to see if it has transitioned from state "init" to "canceled"
        assert put_data["data"]["history"].kind_of?(Array), "Error grabbing the activity data; try running the test suite again. Full response: #{assert put_data["data"]["history"]}"
        history = put_data["data"]["history"]
        assert history.length == 3, "Tested for cancelled claim, but recived the following claim history: #{history.to_s}"

        # exercise the PUT functionality to delete an already deleted claim
        put_data = @@pokitdok.put(activity_url, data={transition: "cancel"})
        refute_nil(put_data["data"]["errors"], msg="The response[data][errors] is empty")
        assert @@pokitdok.status_code == 422, "Status Code assertion failure. Tested for 422 on put to cancel the activity, Observed status code: #{@@pokitdok.status_code}"

        # exercise the activities endpoint to get the status of this claims transaction
        updated_get_response = @@pokitdok.activities(claim_response["meta"]["activity_id"])
        refute_nil(updated_get_response["meta"], msg="the response[meta] section is empty. The full response: #{updated_get_response.to_s}")
        refute_nil(updated_get_response["data"], msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200 on the last use of the activities endpoint, Observed status code: #{@@pokitdok.status_code} #{updated_get_response}"
      end
    end
    #
    # ******************************
    # X12 API tests
    # ******************************
    #
    describe 'X12 API Convenience function test: authorizations' do
      it 'make a call to the live endpoint for: authorizations' do
        @params = {
            event: {
                category: "health_services_review",
                certification_type: "initial",
                delivery: {
                    quantity: 1,
                    quantity_qualifier: "visits"
                },
                diagnoses: [
                    {
                        code: "R10.9",
                        date: "2016-01-25"
                    }
                ],
                place_of_service: "office",
                provider: {
                    organization_name: "KELLY ULTRASOUND CENTER, LLC",
                    npi: "1760779011",
                    phone: "8642341234"
                },
                services: [
                    {
                        cpt_code: "76700",
                        measurement: "unit",
                        quantity: 1
                    }
                ],
                type: "diagnostic_medical"
            },
            patient: {
                birth_date: "1970-01-25",
                first_name: "JANE",
                last_name: "DOE",
                id: "1234567890"
            },
            provider: {
                first_name: "JEROME",
                npi: "1467560003",
                last_name: "AYA-AY"
            },
            trading_partner_id: "MOCKPAYER"
        }
        response = @@pokitdok.authorizations @params
        refute_nil(response["meta"], msg="the response[meta] section is empty")
        refute_nil(response["data"], msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"

      end
    end
    describe 'X12 API Convenience function test: claims_status' do
      it 'make a call to the live endpoint for: claims_status' do
        @params = {
            patient: {
                birth_date: "1970-01-25",
                first_name: "JANE",
                last_name: "DOE",
                id: "1234567890"
            },
            provider: {
                first_name: "Jerome",
                last_name: "Aya-Ay",
                npi: "1467560003"
            },
            service_date: "2014-01-25",
            trading_partner_id: "MOCKPAYER"
        }
        response = @@pokitdok.claims_status @params
        refute_nil(response["meta"].keys, msg="the response[meta] section is empty")
        refute_nil(response["data"].keys, msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"

      end
    end
    describe 'X12 API Convenience function test: claims_convert' do
      it 'make a call to the live endpoint for: claims_convert' do
        response = @@pokitdok.claims_convert('spec/fixtures/test_claim.837')
        refute_nil(response["meta"].keys, msg="the response[meta] section is empty")
        refute_nil(response["data"].keys, msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"

      end
    end
    describe 'X12 API Convenience function test: eligibility' do
      it 'make a call to the live endpoint for: eligibility' do
        params = {
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
        response = @@pokitdok.eligibility params
        refute_nil(response["meta"].keys, msg="the response[meta] section is empty")
        refute_nil(response["data"].keys, msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"
      end
    end
    describe 'X12 API Convenience function test: referrals' do
      it 'make a call to the live endpoint for: referrals' do
        @params = {
            event: {
                category: "specialty_care_review",
                certification_type: "initial",
                delivery: {
                    quantity: 1,
                    quantity_qualifier: "visits"
                },
                diagnoses: [
                    {
                        code: "H72.90",
                        date: "2014-09-25"
                    }
                ],
                place_of_service: "office",
                provider: {
                    first_name: "JOHN",
                    npi: "1154387751",
                    last_name: "FOSTER",
                    phone: "8645822900"
                },
                type: "consultation"
            },
            patient: {
                birth_date: "1970-01-25",
                first_name: "JANE",
                last_name: "DOE",
                id: "1234567890"
            },
            provider: {
                first_name: "CHRISTINA",
                last_name: "BERTOLAMI",
                npi: "1619131232"
            },
            trading_partner_id: "MOCKPAYER"
        }
        response = @@pokitdok.referrals @params
        refute_nil(response["meta"], msg="the response[meta] section is empty")
        refute_nil(response["data"], msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"

      end
    end
    #
    # ******************************
    # Data API tests
    # ******************************
    #
    describe 'Data API Convenience function test: cash_prices' do
      it 'make a call to the live endpoint for: cash_prices' do
        response = @@pokitdok.cash_prices({ zip_code: '29412', cpt_code: '99385'})
        refute_nil(response["meta"], msg="the response[meta] section is empty")
        refute_nil(response["data"], msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"

      end
    end
    describe 'Data API Convenience function test: icd_convert' do
      it 'make a call to the live endpoint for: icd_convert' do
        @params = {code: '250.12'}
        response = @@pokitdok.icd_convert @params
        refute_nil(response["meta"].keys, msg="the response[meta] section is empty")
        refute_nil(response["data"].keys, msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"

      end
    end
    describe 'Data API Convenience function test: mpc' do
      it 'make a call to the live endpoint for: mpc' do
        @params = {code: '99213'}
        response = @@pokitdok.mpc @params
        refute_nil(response["meta"], msg="the response[meta] section is empty")
        refute_nil(response["data"], msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"

      end
    end
    describe 'Data API Convenience function test: insurance_prices' do
      it 'make a call to the live endpoint for: insurance_prices' do
        @params = {zip_code: '94401', cpt_code: '90658'}
        response = @@pokitdok.insurance_prices @params
        refute_nil(response["meta"].keys, msg="the response[meta] section is empty")
        refute_nil(response["data"].keys, msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"

      end
    end
    describe 'Data API Convenience function test: oop_insurance_prices oop_insurance_estimate and oop_insurance_delete_price' do
      it 'make a call to the live endpoint for: oop_insurance_prices oop_insurance_estimate and oop_insurance_delete_price' do
        @params = {
            trading_partner_id: "MOCKPAYER",
            cpt_bundle:["81291", "99999"],
            price: {
                amount: "1300",
                currency: "USD
            }
        }
        response = @@pokitdok.oop_insurance_prices @params
        refute_nil(response["meta"].keys, msg="the response[meta] section is empty")
        refute_nil(response["data"].keys, msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"
        @load_price_uuid = response["data"]["uuid"]

        # run the insurance estimate on that posted price
        @params = {
            trading_partner_id: "MOCKPAYER",
            cpt_bundle: ["81291", "99999"],
            service_type_codes: ["30"],
            eligibility: {
               "provider: {
                    npi: "1912301953",
                    organization_name: "PokitDok, Inc"
                },
                member: {
                    birth_date: "1975-04-26",
                    first_name: "Joe",
                    last_name: "Immortan",
                    id: "999999999"
                }
            }
        }
        response = @@pokitdok.oop_insurance_estimate @params
        refute_nil(response["meta"].keys, msg="the response[meta] section is empty")
        refute_nil(response["data"].keys, msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"

        # delete the price
        response = @@pokitdok.oop_insurance_delete_price @load_price_uuid
        refute_nil(response["meta"].keys, msg="the response[meta] section is empty")
        refute_nil(response["data"].keys, msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"


      end
    end
    describe 'Data API Convenience function test: plans' do
      it 'make a call to the live endpoint for: plans' do
        @params = {state: 'SC', plan_type: 'PPO'}
        response = @@pokitdok.plans @params
        refute_nil(response["meta"], msg="the response[meta] section is empty")
        refute_nil(response["data"], msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"

      end
    end
    describe 'Data API Convenience function test: providers' do
      it 'make a call to the live endpoint for: providers' do
        @params = {npi: '1467560003'}
        response = @@pokitdok.providers @params
        refute_nil(response["meta"], msg="the response[meta] section is empty")
        refute_nil(response["data"], msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"

      end
    end
    describe 'Data API Convenience function test: trading_partners' do
      it 'make a call to the live endpoint for: trading_partners' do
        response = @@pokitdok.trading_partners("aetna")
        refute_nil(response["meta"], msg="the response[meta] section is empty")
        refute_nil(response["data"], msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"
      end
    end

    #
    # ******************************
    # Pharmacy API tests
    # ******************************
    #
    describe 'Pharmacy API Convenience function test: pharmacy_plans' do
      it 'make a call to the live endpoint for: pharmacy_plans' do
        response = @@pokitdok.pharmacy_plans(trading_partner_id:'medicare_national', plan_number:'S5820003')
        refute_nil(response["meta"], msg="the response[meta] section is empty")
        refute_nil(response["data"], msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"

      end
    end
    describe 'Pharmacy API Convenience function test: pharmacy_formulary' do
      it 'make a call to the live endpoint for: pharmacy_formulary' do
        response = @@pokitdok.pharmacy_formulary(trading_partner_id: 'medicare_national', plan_number: 'S5820003', ndc: '00006073554')
        refute_nil(response["meta"], msg="the response[meta] section is empty")
        refute_nil(response["data"], msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"

      end
    end
    describe 'Pharmacy API Convenience function test: pharmacy_network' do
      it 'make a call to the live endpoint for: pharmacy_network' do
        response = @@pokitdok.pharmacy_network(trading_partner_id: 'medicare_national', plan_number: 'S5820003' , zipcode: '07030', radius: '1mi')
        refute_nil(response["meta"], msg="the response[meta] section is empty")
        refute_nil(response["data"], msg="the response[data] section is empty")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"
      end
    end

    #
    # ******************************
    # identity tests
    # ******************************
    #

    describe 'Identity API Convenience function test: validate_identity ' do
      it 'make a call to the live endpoint for: validate_identity' do
        # make a fake identity
        @DUARD = {
            first_name: 'Duard',
            last_name: 'Osinski',
            birth_date: {
                day: 12,
                month: 3,
                year: 1952
            },
            ssn: '491450000',
            address: {city: 'North Perley',
                      country_code: 'US',
                      postal_code: '24330',
                      state_or_province: 'GA',
                      street1: '41072 Douglas Terrace ',
                      street2: 'Apt. 992'
            }
        }
        # test that DUARD is a valid identity
        response = @@pokitdok.validate_identity @DUARD
        refute_nil(response["meta"], msg="the response[meta] section is empty: #{response}")
        refute_nil(response["data"], msg="the response[data] section is empty: #{response}")
        assert @@pokitdok.status_code == 200, "Status Code assertion failure. Tested for 200, Observed status code: #{@@pokitdok.status_code}"
      end
    end
  end
end

