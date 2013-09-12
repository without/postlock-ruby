require 'oauth2'
require File.expand_path("../../postlock/api_record.rb",  __FILE__)

module Postlock
  LOCAL_SERVER_URL = 'http://postlock.dev'
  TEST_SERVER_URL = 'http://postlock-dev.herokuapp.com'
  PRODUCTION_SERVER_URL = 'https://postlock.herokuapp.com'

  class Recipient < ApiRecord::Base
    attributes :name, :email, :code, :created_at
    collection_path 'recipients'
    values_key 'recipient'

    def mailings
      Mailing.all @token, self
    end
  end

  class MailingBatch < ApiRecord::Base
    attributes :expires, :total_cost, :sent
    collection_path 'mailing_batches'
    values_key 'mailing_batch'

    def initialize(token, attributes_hash = {})
      super token, attributes_hash
    end

    def mailings
      Mailing.all @token, self
    end

    def read_only_attributes
      [:expires, :total_cost, :sent]
    end
  end

  class Mailing < ApiRecord::Base
    attributes :mailing_batch_id, :recipient_id, :delivered, :body
    collection_path 'mailings'
    values_key 'mailing'

    def mailing_batch
      MailingBatch.find @token, mailing_batch_id
    end

    def recipient
      Recipient.find @token, recipient_id
    end

    def mailing_items
      mailng_items.all @token, self
    end
  end

  class MailingItem < ApiRecord::Base
    attributes :mailing_item
    collection_path 'mailing_items'
    values_key 'mailing_item'
  end

  class Postlock
    def initialize(client_id, client_secret, redirect_uri, options = {})
      @server_url = case (options[:mode] || :production).to_sym
        when :local then LOCAL_SERVER_URL
        when :test then TEST_SERVER_URL
        else PRODUCTION_SERVER_URL
      end
      @client = OAuth2::Client.new(client_id, client_secret, site: @server_url)
    end

    def login(username, password)
      @api = @client.password.get_token(username, password)
    end
  end
end
