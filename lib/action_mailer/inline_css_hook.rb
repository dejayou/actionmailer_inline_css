#
# Always inline CSS for HTML emails
#
module ActionMailer
  class InlineCssHook
    def self.delivering_email(message)
      if html_part = (message.html_part || (message.content_type =~ /text\/html/ && message))
        start_time = Time.now
        existing_attachments = message.attachments
        # Generate an email with all CSS inlined (access CSS a FS path)
        premailer = ::Premailer.new(html_part.body.to_s,
                                    :with_html_string => true,
                                    :include_style_tags => false,
                                    :preserve_styles => true)

        # Prepend host to remaning URIs.
        # Two-phase conversion to avoid request deadlock from dev. server (Issue #4)
        premailer = ::Premailer.new(premailer.to_inline_css,
                                      :with_html_string => true,
                                      :include_style_tags => false,
                                      :preserve_styles => true,
                                      :base_url => message.header[:host].to_s)
        # Reset the body
        message.body = premailer.to_inline_css
        existing_attachments.each { |attachment| message.body << attachment }
        
        end_time = Time.now
        Rails.logger.info("Premailer took #{end_time - start_time}s") if ENV["ACTION_MAILER_INLINE_CSS_DEBUG"].present?
      end
    end
  end
end
