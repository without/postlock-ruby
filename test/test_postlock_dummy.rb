require 'test_helper'
require 'postlock'
require File.expand_path("../../lib/postlock/api_record_test.rb",  __FILE__)

class PostlockDummyTest < ApiRecord::Dummy::TestCase
  test "is module" do
    assert_kind_of Module, Postlock
  end

  test "batch collection_path" do
    assert_equal 'api/v1/batches', Postlock::Batch.collection_path
  end

  test "batch id" do
    assert_equal nil, Postlock::Batch.new(nil).id
  end

  test "batch new" do
    mb = Postlock::Batch.new nil, batch_attributes
    assert_equal Postlock::Batch, mb.class
    assert_equal nil, mb.id
    mb.assign_read_only 'batch_code' => 12345
  end

  test "batch member_path" do
    assert_equal nil, (mb = Postlock::Batch.new(nil, id: 12345)).member_path
    mb.assign_read_only 'id' => 12345
    assert_equal 12345, mb.id
    assert_equal 'api/v1/batches/12345', mb.member_path
  end

  test "batch index" do
    respond_with array_response(batch_attributes, 'api/v1/batches', 'batch')
    mbs = Postlock::Batch.all self
    assert_request :get, 'api/v1/batches', {}
    mb = mbs.first
    assert_equal 1, mb.id
  end

  test "batch find" do
    respond_with object_response(batch_attributes, 'batch')
    mb = Postlock::Batch.find self, 1
    assert_request :get, 'api/v1/batches/1', {}
    assert_equal 1, mb.id
  end

  test "recipient" do
    respond_with object_response(recipient_attributes, 'recipient')
    recipient = Postlock::Recipient.create self
    assert_equal 'api/v1/recipients/1', recipient.member_path
    assert_equal [:mailings, :is_connected], recipient.read_only_attributes
  end

  test "create recipient" do
    respond_with object_response(recipient_attributes, 'recipient')
    recipient = Postlock::Recipient.create self, recipient_attributes
    assert_request :post, 'api/v1/recipients', recipient: {name: recipient_attributes['name'], email: recipient_attributes['email'], lookup_key: recipient_attributes['lookup_key']}
  end

  test "mailing" do
    respond_with object_response(recipient_attributes, 'recipient')
    r = Postlock::Recipient.create self, recipient_attributes
    respond_with object_response(batch_attributes, 'batch')
    batch = Postlock::Batch.create self
    respond_with object_response(mailing_attributes, 'mailing')
    mailing = Postlock::Mailing.create self, mailing_attributes.merge('recipient_id' => r.id, 'batch_id' => batch.id)
    assert_equal 'api/v1/mailings/1', mailing.member_path
    respond_with object_response(batch_attributes, 'batch')
    assert mailing.batch
    assert_equal 1, mailing.batch.id
  end

  test "document" do
    respond_with object_response(document_attributes, 'document')
    di = Postlock::Document.create self, document_attributes
    assert_equal 'api/v1/documents/1', di.member_path
  end

  private

  def embedded_array(url, hash)
    {'url' => url, 'count' => 1}
  end

  def array(url, hash)
    embedded_array.merge 'type' => 'list', 'data' => [hash]
  end

  def _batch_attributes
    {'id' => 1, 'delivery_status' => 'pending'}
  end

  def batch_attributes
    _batch_attributes.merge 'mailings' => embedded_array('api/v1/batches/12345/mailings', _mailing_attributes)
  end

  def batches
    array 'api/v1/batches', _batch_attributes
  end

  def _recipient_attributes
    {'id' => 1, 'name' => 'recipient name', 'email' => 'recipient@example.com', 'lookup_key' => 'abc123'}
  end

  def recipient_attributes
    _recipient_attributes.merge 'mailings' => embedded_array('api/v1/recipients/1/mailings', _mailing_attributes)
  end

  def recipients
    array 'api/v1/recipients', _recipient_attributes
  end

  def _mailing_attributes
    {'id' => 1, 'recipient_id' => 1, 'recipient' => _recipient_attributes, 'message' => 'body text', 'delivered_at' => DateTime.now}
  end

  def mailing_attributes
    _mailing_attributes.merge 'documents' => embedded_array('api/v1/mailings/1/documents', _document_attributes)
  end

  def _document_attributes
    {'id' => 1, 'description' => 'description', 'content_type' => 'content type', 'content_length' => '54321', 'content' => 'http://...'}
  end

  def document_attributes
    _document_attributes.merge('mailing' => _mailing_attributes)
  end
end
