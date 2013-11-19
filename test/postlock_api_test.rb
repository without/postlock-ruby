require 'test_helper'
require 'postlock'

class PostlockApitest < ActiveSupport::TestCase
  CLIENT_ID = "bc357d70d4676d88c91c3826aac7583f4dc63d34e02a6b8960e02cf47e1505b8"
  CLIENT_SECRET = "544cfa959222d36cbfce272c378f5d134d3392d6b801f152924a6dcf1cdaa508"
  REDIRECT_URI = "http://localhost:3001/oauth2_callback"

  USERNAME = 'email@example.com'
  PASSWORD = 'password'

  @@postlock = Postlock::Postlock.new(CLIENT_ID, CLIENT_SECRET, REDIRECT_URI, mode: :local)
  @@api = @@postlock.login(USERNAME, PASSWORD)

  test "login" do
    assert @@api
  end

  test "create and destroy recipient" do
    create_recipient do |recip|
      [:email, :name].each {|k| assert_equal recipient_attributes[k], recip.send(k) }
    end
  end

  test "recipient mailings" do
    create_recipient do |recip|
      mailings = recip.mailings
      assert_equal "/api/v1/recipients/#{recip.id}/mailings", mailings.url
      assert_equal 0, mailings.length
      assert_equal [], mailings.all
    end
  end

  test "create mailing" do
    create_recipient do |recip|
      create_mailing(mailing_attributes recip) do |mailing|
        assert_equal recip.id, mailing.recipient.id
      end
    end
  end

  test "create mailing with batch" do
    create_recipient do |recip|
      create_mailing(mailing_attributes(recip).merge(batch_code: '12345')) do |mailing|
        assert_equal '12345', mailing.batch_code
        assert mailing.batch_id
        assert_equal '12345', mailing.batch.batch_code
      end
    end
  end

  test "create document" do
    create_recipient do |recip|
      create_mailing(mailing_attributes recip) do |mailing|
        document = mailing.documents.create(document_attributes)
        mailing.reload
        [:id, :description, :content_type, :content_length].each do |k|
          assert_equal [document.send(k)], mailing.documents.map{|d| d.send(k) }
        end
        assert_equal 'something', document.data
      end
    end
  end

  private

  def create_recipient(attributes = nil)
    attributes ||= recipient_attributes
    recipient = Postlock::Recipient.create @@api, attributes
    begin
      yield recipient
    ensure
      recipient.destroy
    end
    nil
  end

  def create_mailing(attributes)
    mailing = Postlock::Mailing.create @@api, attributes
    begin
      yield mailing
    ensure
      mailing.destroy
    end
  end

  def recipient_attributes
    {email: 'test.recipient@example.com', name: 'Test Recipient'}
  end

  def mailing_attributes(recipient)
    {recipient_id: recipient.id, subject: 'Subject', message: 'Body'}
  end

  def document_attributes
    {description: 'a_document', content_type: 'application/pdf', content_length: 1000, content: 'something'}
  end
end
