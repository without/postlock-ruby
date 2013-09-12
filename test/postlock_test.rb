require 'test_helper'
require 'postlock'
require File.expand_path("../../lib/postlock/api_record_test.rb",  __FILE__)

class PostlockTest < ApiRecord::TestCase
  test "is module" do
    assert_kind_of Module, Postlock
  end

  test "mailing_batch collection_path" do
    assert_equal 'api/v1/mailing_batches', Postlock::MailingBatch.collection_path
  end

  test "mailing_batch id" do
    assert_equal 12345, Postlock::MailingBatch.new(nil, id: 12345).id
  end

  test "mailing_batch new" do
    mb = Postlock::MailingBatch.new nil, id: 12345
    assert_equal Postlock::MailingBatch, mb.class
    assert_equal 12345, mb.id
  end

  test "mailing_batch member_path" do
    assert_equal 'api/v1/mailing_batches/12345', Postlock::MailingBatch.new(nil, id: 12345).member_path
  end

  test "mailing_batch index" do
    respond_with [mailing_batch_attributes]
    mbs = Postlock::MailingBatch.all self
    assert_request :get, 'api/v1/mailing_batches', {}
    mb = mbs.first
    assert_equal [1, '2013-09-10', 0], [mb.id, mb.expires, mb.total_cost]
  end

  test "mailing_batch find" do
    respond_with mailing_batch_attributes
    mb = Postlock::MailingBatch.find self, 1
    assert_request :get, 'api/v1/mailing_batches/1', {}
    assert_equal [1, '2013-09-10', 0], [mb.id, mb.expires, mb.total_cost]
  end

  test "mailing_batch create" do
    respond_with mailing_batch_attributes
    mb = Postlock::MailingBatch.create self, expires: '2013-09-10', total_cost: 0
    assert_request :post, 'api/v1/mailing_batches', {}
    assert_equal [1, '2013-09-10', 0], [mb.id, mb.expires, mb.total_cost]
  end

  test "mailing_batch update" do
    respond_with mailing_batch_attributes
    mb = Postlock::MailingBatch.create self, expires: '2013-09-10', total_cost: 0
    mb.save
    assert_request :put, 'api/v1/mailing_batches/1', {}
  end

  private

  def mailing_batch_attributes
    {'mailing_batch' => {'id' => 1, 'expires' => '2013-09-10', 'total_cost' => 0, 'sent' => false}}
  end
end
