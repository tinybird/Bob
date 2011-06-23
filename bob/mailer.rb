require 'rubygems'
require 'action_mailer'

class Mailer < ActionMailer::Base
  helper :mailer
  
  def build_report(build, recipients, from, subject, message)
    @subject      = "[Bob] #{subject.capitalize}"
    @content_type = "text/html"
    @build        = build
    @message      = message
    @recipients   = recipients
    @from         = from
    @sent_on      = Time.now
    @headers      = {}
  end

  def build_failure(recipients, from, subject, message)
    @subject      = "[Bob] #{subject.capitalize}"
    @content_type = "text/html"
    @message      = message
    @recipients   = recipients
    @from         = from
    @sent_on      = Time.now
    @headers      = {}
  end

end

Mailer.prepend_view_path(File.dirname(__FILE__) + '/../templates')
Mailer.logger = nil #BobLogger.get # for debugging
