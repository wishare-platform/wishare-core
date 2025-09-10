require 'sendgrid-ruby'

class SendgridApiDelivery
  include SendGrid
  
  attr_accessor :settings
  
  def initialize(settings)
    @settings = settings
  end
  
  def deliver!(mail)
    sg = SendGrid::API.new(api_key: settings[:api_key])
    
    from = Email.new(email: mail.from.first, name: mail[:from].display_names.first)
    subject = mail.subject
    
    # Handle multiple recipients
    personalization = Personalization.new
    
    # Add TO recipients
    if mail.to
      mail.to.each do |recipient|
        personalization.add_to(Email.new(email: recipient.strip))
      end
    end
    
    # Add CC recipients if present
    if mail.cc
      mail.cc.each do |recipient|
        personalization.add_cc(Email.new(email: recipient.strip))
      end
    end
    
    # Add BCC recipients if present
    if mail.bcc
      mail.bcc.each do |recipient|
        personalization.add_bcc(Email.new(email: recipient.strip))
      end
    end
    
    # Create mail content
    content = []
    
    # Add text content if present
    if mail.text_part
      content << Content.new(type: 'text/plain', value: mail.text_part.body.to_s)
    elsif !mail.multipart? && mail.content_type =~ /text\/plain/
      content << Content.new(type: 'text/plain', value: mail.body.to_s)
    end
    
    # Add HTML content if present
    if mail.html_part
      content << Content.new(type: 'text/html', value: mail.html_part.body.to_s)
    elsif !mail.multipart? && mail.content_type =~ /text\/html/
      content << Content.new(type: 'text/html', value: mail.body.to_s)
    end
    
    # Build the mail object
    sg_mail = SendGrid::Mail.new
    sg_mail.from = from
    sg_mail.subject = subject
    sg_mail.add_personalization(personalization)
    
    content.each do |c|
      sg_mail.add_content(c)
    end
    
    # Send the email
    response = sg.client.mail._('send').post(request_body: sg_mail.to_json)
    
    # Log the response for debugging
    if response.status_code.to_i >= 400
      Rails.logger.error "SendGrid API Error: #{response.status_code} - #{response.body}"
      raise "SendGrid API Error: #{response.status_code} - #{response.body}"
    else
      Rails.logger.info "Email sent successfully via SendGrid API: #{response.status_code}"
    end
    
    response
  end
end