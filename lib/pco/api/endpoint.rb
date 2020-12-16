# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'

module PCO
  module API
    URL = 'https://api.planningcenteronline.com'

    class Endpoint
      attr_reader :url, :last_result

      def initialize(url: URL, oauth_access_token: nil, basic_auth_token: nil, basic_auth_secret: nil, connection: nil)
        @url = url
        @oauth_access_token = oauth_access_token
        @basic_auth_token = basic_auth_token
        @basic_auth_secret = basic_auth_secret
        @connection = connection || _build_connection
        @cache = {}
      end

      def method_missing(method_name, *_args)
        _build_endpoint(method_name.to_s)
      end

      def [](id)
        _build_endpoint(id.to_s)
      end

      def respond_to?(method_name)
        endpoint = _build_endpoint(method_name.to_s)
        begin
          endpoint.get
        rescue Errors::NotFound
          false
        else
          true
        end
      end

      def get(params = {})
        @last_result = @connection.get(@url, params)
        _build_response(@last_result)
      end

      def post(body = {})
        @last_result = @connection.post(@url) do |req|
          req.body = _build_body(body)
        end
        _build_response(@last_result)
      end

      def patch(body = {})
        @last_result = @connection.patch(@url) do |req|
          req.body = _build_body(body)
        end
        _build_response(@last_result)
      end

      def delete
        @last_result = @connection.delete(@url)
        if @last_result.status == 204
          true
        else
          _build_response(@last_result)
        end
      end

      private

      def _build_response(result)
        case result.status
        when 200..299
          res = result.body
          res['headers'] = result.headers
          res
        when 400
          raise Errors::BadRequest, result
        when 401
          raise Errors::Unauthorized, result
        when 403
          raise Errors::Forbidden, result
        when 404
          raise Errors::NotFound, result
        when 405
          raise Errors::MethodNotAllowed, result
        when 422
          raise Errors::UnprocessableEntity, result
        when 429
          raise Errors::TooManyRequests, result
        when 400..499
          raise Errors::ClientError, result
        when 500
          raise Errors::InternalServerError, result
        when 500..599
          raise Errors::ServerError, result
        else
          raise "unknown status #{result.status}"
        end
      end

      def _build_body(body)
        if _needs_url_encoded?
          Faraday::Utils.build_nested_query(body)
        else
          body.to_json
        end
      end

      def _needs_url_encoded?
        @url =~ %r{oauth/[a-z]+\z}
      end

      def _build_endpoint(path)
        @cache[path] ||= begin
          self.class.new(
            url: File.join(url, path.to_s),
            connection: @connection
          )
        end
      end

      def _build_connection
        Faraday.new(url: url) do |faraday|
          faraday.response :json, content_type: /\bjson$/
          if @basic_auth_token && @basic_auth_secret
            faraday.basic_auth @basic_auth_token, @basic_auth_secret
          elsif @oauth_access_token
            faraday.headers['Authorization'] = "Bearer #{@oauth_access_token}"
          else
            raise Errors::AuthRequiredError,
                  'You must specify either HTTP basic auth credentials or an OAuth2 access token.'
          end
          faraday.adapter :excon
        end
      end
    end
  end
end
