require 'oauth2'

# OAuth 2.0 Client implementation for Ruby.
class OAuthApplicationClient
  attr_accessor :token, :user_agent

  # Connect to the PokitDok API with the specified Client ID and Client
  # Authentication logic located within this class.
  #
  # +client_id+     your client ID, provided by PokitDok
  # +client_secret+ your client secret, provided by PokitDok
  # +token_url+ token url to be appended for authentication. Defaults to '/oauth2/token'
  # +redirect_uri+ the Redirect URI set for the PokitDok Platform Application.
  #   This value is managed at https://platform.pokitdok.com in the App Settings
  # +scope+ a list of scope names that should be used when requesting authorization
  # +code+ code value received from an authorization code grant
  # +token+ The current API access token for your PokitDok Platform Application. If not provided a new token is generated.
  # +user_agent+ user agent to be used as a header in HTTP requests
  def initialize(client_id, client_secret, token_url, redirect_uri, scope, code, token, user_agent)
    @client_id = client_id
    @client_secret = client_secret
    @token_url = token_url
    @redirect_uri = redirect_uri
    @scope = scope
    @code = code
    @user_agent = user_agent
    @token  = token

    @api_client = OAuth2::Client.new(@client_id, @client_secret, site: @api_url, token_url: @token_url, raise_errors: false)
    if @token.nil?
      fetch_access_token(@code)
    end
  end

  # Perform a GET request given the http request path and optional params
  #
  # +path+ request path
  # +params+ an optional hash of parameters that will be sent in the request
  def get_request(path, params, &block)
    if isAccessTokenExpired?
      fetch_access_token()
    end
    @token.get(path, params: params, headers: headers, &block)
  end

  # Perform a PUT request given the http request path and optional params
  #
  # +path+ request path
  # +params+ an optional hash of parameters that will be sent in the request
  def put_request(path, params = {}, &block)
    if isAccessTokenExpired?
      fetch_access_token()
    end
    headers.merge({ headers: { :'Content-Type' => 'application/json'}})
    @token.put(path, body: params.to_json, headers: headers({:'Content-Type' => 'application/json'}), &block)
  end

  # Perform a POST request given the http request path and optional params
  #
  # +path+ request path
  # +params+ an optional hash of parameters that will be sent in the request
  def post_request(path, params = {}, &block)
    if isAccessTokenExpired?
      fetch_access_token()
    end
    headers.merge({ headers: { :'Content-Type' => 'application/json'}})
    @token.post(path, body: params.to_json, headers: headers({:'Content-Type' => 'application/json'}), &block)
  end

  # Perform a POST request given the http request path, a file and optional params
  #
  # +path+ request path
  # +file+ the file to be sent with the request
  # +params+ an optional hash of parameters that will be sent in the request
  def post_file(endpoint, file=nil, params={})
    if isAccessTokenExpired?
      fetch_access_token()
    end
    url = URI.parse(@api_url + endpoint)

    File.open(file) do |f|
      additional_params = params.merge({'file' => UploadIO.new(f, 'application/EDI-X12', file)})
      req = Net::HTTP::Post::Multipart.new(url.path, additional_params)

      req['Authorization'] = "Bearer #{self.token.token}"
      req['User-Agent'] = @user_agent

      @response = Net::HTTP.start(url.host, url.port) do |http|
        http.request(req)
      end
      JSON.parse(@response.body)
    end
  end

  # Perform a DELETE request given the http request path and optional params
  #
  # +path+ request path
  # +params+ an optional hash of parameters that will be sent in the request
  def delete_request(path, params = {}, &block)
    if isAccessTokenExpired?
      fetch_access_token()
    end
    @token.delete(path, body: params.to_json, headers: headers({:'Content-Type' => 'application/json'}), &block)
  end

  # Construct OAuth2 Authorization Grant URL
  def authorization_url()
    if @redirect_uri.nil? || @scope.nil?
      raise 'A redirect_uri and scope must be specified when the client is instantiated in order to get a working authorization URL'
    end
    @api_client.auth_code.authorize_url(redirect_uri: @redirect_uri, scope: @scope)
  end

  ### PRIVATE METHODS ###

  # Retrieves an OAuth2 access token.  If `code` is not specified, the client_credentials
  # grant type will be used based on the client_id and client_secret.  If `code` is not None,
  # an authorization_code grant type will be used.
  #
  # +code+ optional authorization code used for scope purposes
  def fetch_access_token(code = nil)
    if code
      # Currently non functioning as our OAuth2 authorization_code grant type is not implemented on the server
      params =  {
          headers: { 'Authorization' => 'Basic' },
          scope: @scope,
          redirect_uri: @redirect_uri
      }
      @token = @api_client.auth_code.get_token(code, params)
    else
      @token = @api_client.client_credentials.get_token(headers: { 'Authorization' => 'Basic' })
    end
  end

  # Returns a standard set of headers to be passed along with all requests
  def headers(additional_headers = {})
    { 'User-Agent' => @user_agent }.merge(additional_headers)
  end

  # Check if the access token is expired
  def isAccessTokenExpired?
    if !@token.is_a?(OAuth2::AccessToken)
      return true
    end
    @token.expired?
  end

  private :headers, :isAccessTokenExpired?, :fetch_access_token
end