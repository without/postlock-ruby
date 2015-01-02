require 'test_helper'
require 'postlock'

class TestPostlock < ActiveSupport::TestCase
  CLIENT_ID = "bc357d70d4676d88c91c3826aac7583f4dc63d34e02a6b8960e02cf47e1505b8"
  CLIENT_SECRET = "544cfa959222d36cbfce272c378f5d134d3392d6b801f152924a6dcf1cdaa508"
  REDIRECT_URI = "http://localhost:3001/oauth2_callback"

  USERNAME = 'email@example.com'
  PASSWORD = 'password'

  @@postlock = Postlock::Service.new(CLIENT_ID, CLIENT_SECRET, REDIRECT_URI, mode: :local)
  @@api = @@postlock.login(USERNAME, PASSWORD)

  test "login" do
    assert @@api
  end

  test "create and destroy recipient" do
    create_recipient do |recip|
      [:email, :name].each {|k| assert_equal recipient_attributes[k], recip.send(k) }
    end
  end

  test "postlock recipients" do
    assert !@@postlock.recipients.all.empty?
  end

  test "postlock batches" do
    assert !@@postlock.batches.all.empty?
  end

  test "find postlock recipients" do
    recip = @@postlock.recipients.first
    assert_equal recip.id, @@postlock.recipients.find(recip.id).try(:id)
  end

  test "find postlock batches" do
    batch = @@postlock.batches.first
    assert_equal batch.id, @@postlock.batches.find(batch.id).try(:id)
  end

  test "postlock security_questions" do
    # @@postlock.security_questions.all.each {|s| s.destroy }
    create_security_question do |security_question|
      assert security_question.id
    end
  end

  test "recipient security_answers" do
    create_recipient do |recip|
      security_answers = recip.security_answers
      assert_equal "/api/v1/recipients/#{recip.id}/security_answers", security_answers.url
      assert_equal 0, security_answers.length
      create_security_question do |security_question|
        security_answer = security_answers.create security_question_id: security_question.id, answer: answer = '12345'
        assert security_answer.id
        security_answers = recip.security_answers.all
        assert !security_answers.find{|o| o.id <=> security_answer.id}.answer
        assert_equal answer, security_answer.answer
        security_answer.destroy
      end
    end
  end

  test "recipient mailings" do
    create_recipient do |recip|
      mailings = recip.mailings
      assert_equal "/api/v1/recipients/#{recip.id}/mailings", mailings.url
      assert_equal 0, mailings.length
      assert_equal [], mailings.all
      mailing = mailings.create(subject: subject = 'sub', message: message = 'msg')
      assert mailing.id
      assert_equal subject, mailing.subject
      assert_equal message, mailing.message
      mailing.destroy
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
    batch = @@postlock.batches.create
    create_recipient do |recip|
      create_mailing(mailing_attributes(recip).merge(batch_id: batch.id)) do |mailing|
        assert mailing.batch_id
        assert_equal batch.id, mailing.batch_id
        assert_equal batch.id, mailing.batch.id
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
    recipient = @@postlock.recipients.create attributes
    begin
      yield recipient
    ensure
      recipient.destroy
    end
    nil
  end

  def create_mailing(attributes)
    recipient = @@postlock.recipients.find attributes.delete(:recipient_id)
    mailing = recipient.mailings.create attributes
    begin
      yield mailing
    ensure
      mailing.destroy
    end
  end

  def create_security_question
    security_question = @@postlock.security_questions.create(question: 'q')
    begin
      yield security_question
    ensure
      security_question.destroy
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
