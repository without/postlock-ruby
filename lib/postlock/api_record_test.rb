module ApiRecord
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
      @request_params = params
      return self
    end

    def assert_request method, path, params
      assert_equal method, @request_method
      assert_equal path, @request_path
      assert_equal params, @request_params
    end

    def respond_with(desired_response)
      @desired_response = desired_response
    end
  end
end
