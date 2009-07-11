class Mailer < ActionMailer::Base

  def feedback(subject, user, question, email, feedback)
    setup_email(user)
    @subject += subject
    @body[:question] = question
    @body[:email] = email
    @body[:feedback] = feedback
  end

  def add_item(subject, user, question, question_id, item, item_id)
    setup_email(user)
    @subject += "#{subject}: #{question}"
    code = Base64.encode64("#{question_id}-#{item_id}")
    @body[:path] = activate_items_path(:id => code, :only_path => false, :host => @body[:host])
    @body[:question] = question
    @body[:question_id] = question_id
    @body[:item] = item
  end

  def password(user)
    setup_email(user)
    @body[:password] = Base64.decode64(user.encoded_password)
  end
  
  protected
    def setup_email(user)
      @recipients  = user.email
      @from        = "info@allourideas.org"
      @subject     = "[All Our Ideas] "
      @content_type = "text/html"
      @sent_on     = Time.now
      @body[:user] = user
      @body[:host] = "www.allourideas.org"
    end

end