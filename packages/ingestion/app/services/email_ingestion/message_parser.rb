# frozen_string_literal: true

require "mail"

class EmailIngestion::MessageParser
  def initialize(file_path)
    @file_path = file_path
  end

  def call
    mail = Mail.read(@file_path)

    {
      message_id: mail.message_id,
      from: mail.from&.first,
      subject: mail.subject,
      date: mail.date,
      text_body: extract_text_body(mail),
      html_body: extract_html_body(mail),
      headers: mail.headers.to_h
    }
  end

  private

  def extract_text_body(mail)
    return mail.body.decoded if mail.mime_type == "text/plain"
    return mail.text_part.decoded if mail.multipart? && mail.text_part
    nil
  end

  def extract_html_body(mail)
    return mail.body.decoded if mail.mime_type == "text/html"
    return mail.html_part.decoded if mail.multipart? && mail.html_part
    nil
  end
end
