module ApiRecord
  module Dummy
    class TestCase < ActiveSupport::TestCase
      def get(path, params = {})
        request :get, path, params
      end

      def post(path, params = {})
        request :post, path, params
      end

      def put(path, params = {})
        request :put, path, params
      end

      def delete(path, params = {})
        request :delete, path, params
      end

      def parsed
        @desired_response
      end

      private

      def request(method, path, params)
        @request_method = method
        @request_path = path
        @request_params = params[:body] || {}.to_json
        return self
      end

      def assert_request method, path, params
        assert_equal method, @request_method
        assert_equal path, @request_path
        assert_equal params.to_json, @request_params
      end

      def respond_with(desired_response)
        @desired_response = desired_response
      end

      def object_response(values_hash, object_type)
        values_hash.merge 'object' => object_type.to_s
      end

      def array_response(values_hash, url, object_type)
        {'object' => 'list', 'url' => url, 'count' => '1', 'data' => [object_response(values_hash, object_type)]}
      end
    end
  end
end
