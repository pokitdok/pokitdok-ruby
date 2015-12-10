# -*- coding: utf-8 -*-
#
# Copyright (C) 2014-2015, All Rights Reserved, PokitDok, Inc.
# https://www.pokitdok.com
#
# Please see the LICENSE.txt file for more information.
# All other rights reserved.
#

require 'rubygems'
require 'bundler/setup'
require 'base64'
require 'json'
require 'oauth2'
require 'net/http/post/multipart'

module PokitDok
  # PokitDok API client implementation for Ruby.
  class PokitDok
    POKITDOK_URL_BASE = 'https://platform.pokitdok.com' # :nodoc:

    attr_reader :client # :nodoc:
    attr_reader :api_url
    attr_reader :version

    # Connect to the PokitDok API with the specified Client ID and Client
    # Secret.
    #
    # +client_id+     your client ID, provided by PokitDok
    #
    # +client_secret+ your client secret, provided by PokitDok
    #
    def initialize(client_id, client_secret, version='v4')
      @client_id = client_id
      @client_secret = client_secret
      @version = version

      @api_url = "#{url_base}/api/#{version}"
      @client = OAuth2::Client.new(@client_id, @client_secret,
                                   site: @api_url, token_url: '/oauth2/token')


      @scopes = {}
      @scopes['default'] = { scope: refresh_token }
      scope 'default'
    end

    # Accessor for the PokitDok Platform URL, overridable for testing.
    def url_base
      POKITDOK_URL_BASE
    end

    # Adds an authorization code for a given OAuth2 scope.
    #
    # +name+ the scope name
    # +code+ the authorization code
    #
    def scope_code(name, code)
      @scopes[name] = { code: code }
    end

    # Invokes the appointments endpoint, to query for open appointment slots
    # (using pd_provider_uuid and location) or booked appointments (using
    # patient_uuid).
    #
    # +params+ an optional Hash of parameters
    #
    def activities(params = {})
      activity_id = params.delete(:activity_id)

      scope 'default'
      get("activities/#{activity_id}", params)
    end

    # Invokes the authorizations endpoint.
    #
    # +params+ an optional hash of parameters that will be sent in the POST body
    #
    def authorizations(params = {})
      scope 'default'
      post('authorizations/', params)
    end

    # Invokes the cash prices endpoint.
    #
    # +params+ an optional hash of parameters that will be sent in the POST body
    #
    def cash_prices(params = {})
      scope 'default'
      get('prices/cash', params)
    end

    # Invokes the claims endpoint.
    #
    # +params+ an optional hash of parameters that will be sent in the POST body
    #
    def claims(params = {})
      scope 'default'
      post('claims/', params)
    end

    # Invokes the claims status endpoint.
    #
    # +params+ an optional hash of parameters that will be sent in the POST body
    #
    def claims_status(params = {})
      scope 'default'
      post('claims/status', params)
    end

    # Invokes the eligibility endpoint.
    #
    # +params+ an optional hash of parameters that will be sent in the POST body
    #
    def eligibility(params = {})
      scope 'default'
      post('eligibility/', params)
    end

    # Invokes the enrollment endpoint.
    #
    # +params+ an optional hash of parameters that will be sent in the POST body
    #
    def enrollment(params = {})
      scope 'default'
      post('enrollment/', params)
    end

    # Uploads an EDI file to the files endpoint.
    # Uses the multipart-post gem, since oauth2 doesn't support multipart.
    #
    # +trading_partner_id+ the trading partner to transmit to
    # +filename+ the path to the file to transmit
    #
    def files(trading_partner_id, filename)
      scope 'default'
      url = URI.parse(@api_url + '/files/')

      File.open(filename) do |f|
        req = Net::HTTP::Post::Multipart.new url.path,
          'file' => UploadIO.new(f, 'application/EDI-X12', filename),
          'trading_partner_id' => trading_partner_id
        req['Authorization'] = "Bearer #{default_scope.token}"
        req['User-Agent'] = user_agent

        @response = Net::HTTP.start(url.host, url.port) do |http|
          http.request(req)
        end
      end

      JSON.parse(@response.body)
    end

    # Invokes the insurance prices endpoint.
    #
    # +params+ an optional hash of parameters
    #
    def insurance_prices(params = {})
      scope 'default'
      get('prices/insurance', params)
    end

    # Invokes the payers endpoint.
    #
    # +params+ an optional hash of parameters
    #
    def payers(params = {})
      scope 'default'
      get('payers/', params)
    end

    # Invokes the plans endpoint.
    #
    # +params+ an optional Hash of parameters
    #
    def plans(params = {})
      scope 'default'
      get('plans/', params)
    end

    # Invokes the providers endpoint.
    #
    # +params+ an optional Hash of parameters
    #
    def providers(params = {})
      response = default_scope.get('providers/') do |request|
        request.params = params
      end
      JSON.parse(response.body)
    end

    # Invokes the referrals endpoint.
    #
    # +params+ an optional Hash of parameters
    #
    def referrals(params = {})
      scope 'default'
      post('referrals/', params)
    end

    # Invokes the trading partners endpoint.
    #
    # +params+ an optional Hash of parameters
    #
    def trading_partners(params = {})
      trading_partner_id = params.delete(:trading_partner_id)

      response =
        default_scope.get("tradingpartners/#{trading_partner_id}") do |request|
          request.params = params
        end
      JSON.parse(response.body)
    end

    # Scheduling endpoints

    # Invokes the appointments endpoint to query for an open appointment
    # slot or a booked appointment given a specific pd_appointment_uuid,
    # the PokitDok unique appointment identifier.
    #
    # +params+ an optional Hash of parameters
    #
    def appointment(params = {})
      @appointment_id = params.delete(:appointment_id)
      scope 'user_schedule'

      get_one('schedule/appointmenttypes/', @appointment_id, params)
    end

    # Invokes the activities endpoint.
    #
    # This endpoint uses the user_schedule OAuth2 scope. You'll need to
    # get the user's authorization via our OAuth2 provider, and pass the
    # authorization code you received into
    # scope_code('user_schedule', '(the authorization code)')
    #
    # +params+ an optional Hash of parameters
    #
    def appointments(params = {})
      scope 'user_schedule'
      get('schedule/appointments/', params)
    end

    # Invokes the appointment_types endpoint, to get information on a specific
    # appointment type.
    #
    # +params+ an optional Hash of parameters
    #
    def appointment_type(params = {})
      appointment_type = params.delete(:uuid)

      response =
      default_scope.get("schedule/appointmenttypes/#{appointment_type}") do |request|
        request.params = params
      end

      JSON.parse(response.body)
    end

    # Invokes the appointment_types endpoint.
    #
    # +params+ an optional hash of parameters
    #
    def appointment_types(params = {})
      scope 'default'
      get('schedule/appointmenttypes/', params)
    end

    # Books an appointment.
    #
    # This endpoint uses the user_schedule OAuth2 scope. You'll need to
    # get the user's authorization via our OAuth2 provider, and pass the
    # authorization code you received into
    # scope_code('user_schedule', '(the authorization code)')
    #
    # +params+ an optional hash of parameters that will be sent in the POST body
    #
    def book_appointment(appointment_uuid, params = {})
      scope 'user_schedule'

      put_one("schedule/appointments", appointment_uuid, params)
    end

    # Cancels the specified appointment.
    #
    # This endpoint uses the user_schedule OAuth2 scope. You'll need to
    # get the user's authorization via our OAuth2 provider, and pass the
    # authorization code you received into
    # scope_code('user_schedule', '(the authorization code)')
    #
    # +params+ an optional Hash of parameters
    #
    def cancel_appointment(appointment_uuid, params={})
      scope 'user_schedule'

      delete_one("schedule/appointments", appointment_uuid, params)
    end

    # Invokes the schedule/appointments endpoint.
    #
    # This endpoint uses the user_schedule OAuth2 scope. You'll need to
    # get the user's authorization via our OAuth2 provider, and pass the
    # authorization code you received into
    # scope_code('user_schedule', '(the authorization code)')
    #
    # +params+ an optional hash of parameters
    #
    def open_appointment_slots(params = {})
      scope 'user_schedule'
      get('schedule/appointments', params)
    end

    # Invokes the schedulers endpoint.
    #
    # +params an optional Hash of parameters
    #
    def schedulers(params = {})
      scope 'default'
      get('schedule/schedulers/', params)
    end

    # Invokes the schedulers endpoint, to get information about a specific
    # scheduler.
    #
    # +params+ an optional Hash of parameters
    #
    def scheduler(params = {})
      scheduler_id = params.delete(:uuid)

      response =
        default_scope.get("schedule/schedulers/#{scheduler_id}") do |request|
          request.params = params
        end
      JSON.parse(response.body)
    end

    # Invokes the slots endpoint.
    #
    # This endpoint uses the user_schedule OAuth2 scope. You'll need to
    # get the user's authorization via our OAuth2 provider, and pass the
    # authorization code you received into
    # scope_code('user_schedule', '(the authorization code)')
    #
    # +params+ an optional Hash of parameters
    #
    def slots(params = {})
      scope 'user_schedule'
    end

    # Updates the specified appointment.
    #
    # This endpoint uses the user_schedule OAuth2 scope. You'll need to
    # get the user's authorization via our OAuth2 provider, and pass the
    # authorization code you received into
    # scope_code('user_schedule', '(the authorization code)')
    #
    # +params+ an optional Hash of parameters
    #
    def update_appointment(appointment_uuid, params={})
      scope 'user_schedule'

      put_one("schedule/appointments", appointment_uuid, params)
    end

    private
      # Returns a standard User-Agent string to be passed along with all requests
      def user_agent
        "pokitdok-ruby 0.8 #{RUBY_DESCRIPTION}"
      end

      # Returns a standard set of headers to be passed along with all requests
      def headers
        { 'User-Agent' => user_agent }
      end

      def get(endpoint, params = {})
        response = current_scope.get(endpoint, headers: headers, params: params)

        JSON.parse(response.body)
      end

      def get_one(endpoint, id, params = {})
        response = current_scope.get("#{endpoint}/#{id}", headers: headers,
                                 body: params.to_json) do |request|
          request.headers['Content-Type'] = 'application/json'
        end

        JSON.parse(response.body)
      end

      def post(endpoint, params = {})
        response = current_scope.post(endpoint, headers: headers,
                               body: params.to_json) do |request|
          request.headers['Content-Type'] = 'application/json'
        end

        JSON.parse(response.body)
      end

      def put_one(endpoint, id, params = {})
        response = current_scope.put("#{endpoint}/#{id}", headers: headers,
                                 body: params.to_json) do |request|
          request.headers['Content-Type'] = 'application/json'
        end

        JSON.parse(response.body)
      end

      def delete_one(endpoint, id, params = {})
        response = current_scope.delete("#{endpoint}/#{id}", headers: headers,
                                 body: params.to_json) do |request|
          request.headers['Content-Type'] = 'application/json'
        end

        if response.body.empty?
          response.status == 204
        else
          JSON.parse(response.body)
        end
      end

      # Refreshes the client token associated with this PokitDok connection
      #
      # FIXME: automatic refresh on expiration
      #
      def refresh_token(code=nil)
        body = {}
        body[:code] = code unless code.nil?

        @client.client_credentials.get_token(
          headers: { 'Authorization' => 'Basic' })
      end

      def scope(name)
        raise ArgumentError, "You need to provide an authorization code for " \
          "the scope #{name} with the scope_code method" if @scopes[name].nil?

        @current_scope = name

        if @scopes[name][:scope].nil?
          @scopes[name][:scope] = refresh_token(@scopes[name][:code])
        end

        @scopes[name][:scope]
      end

      def current_scope
        @scopes[@current_scope][:scope]
      end

      def default_scope
        @scopes['default'][:scope]
      end
  end
end
