require File.expand_path("../../postlock/api_record.rb",  __FILE__)
require 'oauth2'

module Postlock
  LOCAL_SERVER_URL = 'http://postlock.dev'
  STAGING_SERVER_URL = 'http://postlock-dev.herokuapp.com'
  PRODUCTION_SERVER_URL = 'https://postlock.herokuapp.com'

  class Document < ApiRecord::Base
    attributes :description, :content_type, :content_length, :content, :mailing
    collection_path 'documents'
    values_key :document

    def attributes_hash(options = {})
      (options[:except] ||= []) << :content
      super(options).merge(content: Base64.encode64(content))
    end

    def read_only_attributes
      [:mailing]
    end

    def content=(value)
      @content = value.respond_to?(:read) ? value.read : value
    end

    def data
      @token.get(content).response.body
    end
  end

  class Mailing < ApiRecord::Base
    attributes :batch_id, :batch_code, :recipient_id, :recipient, :subject, :delivery_status, :delivered_at, :read_status, :read_at, :message, :documents
    collection_path 'mailings'
    values_key :mailing
    has_many :documents, Document

    def batch
      Batch.find @token, batch_id
    end

    def recipient
      @_recipient ||= Recipient.new_from_server(@token, @recipient)
    end

    def recipient=(value)
      @recipient = value
      @_recipient = nil
    end

    def read_only_attributes
      [:batch_id, :recipient, :delivery_status, :delivered_at, :read_status, :read_at, :documents]
    end
  end

  class Recipient < ApiRecord::Base
    attributes :name, :email, :is_connected
    collection_path 'recipients'
    values_key :recipient
    has_many :mailings, Mailing

    def read_only_attributes
      [:mailings, :is_connected]
    end
  end

  class Batch < ApiRecord::ReadOnlyDeletable
    attributes :batch_code, :status, :mailings
    collection_path 'batches'
    values_key :batch

    def initialize(token, attributes_hash = {})
      super token, attributes_hash
    end

    def mailings
      Mailing.all @token, self
    end

    def read_only_attributes
      [:batch_code, :status, :mailings]
    end
  end

  class Postlock
    def initialize(client_id, client_secret, redirect_uri, options = {})
      @server_url = case (options[:mode] || :production).to_sym
        when :local then LOCAL_SERVER_URL
        when :staging then STAGING_SERVER_URL
        else PRODUCTION_SERVER_URL
      end
      @client = OAuth2::Client.new client_id, client_secret, site: @server_url, connection_opts: {headers: {'Content-Type' => 'application/json'}}
    end

    def login(username, password)
      @api = @client.password.get_token(username, password)
    end
  end
end
