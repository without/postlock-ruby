require File.expand_path("../../postlock/api_record.rb",  __FILE__)
require 'oauth2'

module Postlock
  LOCAL_SERVER_URL = 'http://postlock.dev'
  STAGING_SERVER_URL = 'http://postlock-dev.herokuapp.com'
  PRODUCTION_SERVER_URL = 'https://postlock.herokuapp.com'

  class Document < ApiRecord::Base
    attributes :mailing_id, :mailing, :description, :content_type, :content_length, :content
    collection_path 'documents'
    values_key :document

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
    attributes :batch_id, :recipient_id, :recipient, :subject, :delivery_status, :delivered_at, :read_status, :read_at, :message, :documents
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
      read_onlies = [:recipient, :delivery_status, :delivered_at, :read_status, :read_at, :documents].tap do |ro|
        ro << :batch_id if new_record?
      end
    end
  end

  class SecurityAnswer < ApiRecord::Base
    attributes :security_question_id, :security_question, :answer
    collection_path 'security_answers'
    values_key :security_answer

    def read_only_attributes
      [:security_question]
    end
  end

  class Recipient < ApiRecord::Base
    attributes :name, :email, :is_connected, :lookup_key
    collection_path 'recipients'
    values_key :recipient
    has_many :mailings, Mailing
    has_many :security_answers, SecurityAnswer

    def read_only_attributes
      [:mailings, :security_answers, :is_connected]
    end
  end

  class SecurityQuestion < ApiRecord::Base
    attributes :question
    collection_path 'security_questions'
    values_key :security_question
  end

  class Batch < ApiRecord::Base
    attributes :delivery_status, :mailings
    collection_path 'batches'
    values_key :batch

    def initialize(token, attributes_hash = {})
      super token, attributes_hash
    end

    def mailings
      Mailing.all @token, self
    end

    def read_only_attributes
      [:delivery_status, :mailings]
    end
  end

  class Service
    attr_accessor :access_token

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

    {
      recipients: Recipient,
      batches: Batch,
      security_questions: SecurityQuestion
    }.each do |association_name, element_class|
      attribute_name = "_#{association_name}"
      attr_reader attribute_name
      define_method(association_name) do
        ApiRecord::ArrayWrapper.new @api, element_class, 'url' => "api/v1/#{association_name}"
      end
    end
  end
end
