description 'Anti-Spam'
require 'net/http'

RECAPTCHA_PUBLIC = Config['antispam.recaptcha.public']
RECAPTCHA_PRIVATE = Config['antispam.recaptcha.private']

class SpamEvaluator
  def self.bad_words
    @bad_words ||= File.read(File.join(File.dirname(__FILE__), 'antispam.words')).split("\n")
  end

  def initialize(params, page)
    @params = params
    @page = page
  end

  def evaluate
    level = 0
    SpamEvaluator.instance_methods.select {|m| m.to_s.starts_with?('eval_') }.each do |m|
      level += send(m) || 0
    end
    level.to_i
  end

  def eval_uri_percentage
    data = @params[:content].to_s
    if data.size > 0
      size = 0
      data.scan(/((http|ftp):\/\/\S+?)(?=([,.?!:;"'\)])?(\s|$))/) { size += $1.size }
      ((size.to_f / data.size) * 300).to_i
    end
  end

  def eval_change_size
    data = @params[:content].to_s
    if !@page.new? && @page.content.size > 1024
      ratio = data.size.to_f / @page.content.size
      if ratio == 0
        100
      elsif ratio < 1
        50 / ratio
      else
        50 * ratio
      end
    end
  end

  def eval_spam_words
    data = @params[:content].to_s.downcase
    SpamEvaluator.bad_words.any? {|word| data.index(word) } ? 100 : 0
  end

  def eval_uri_in_comment
    @params[:comment].to_s =~ %r{http://} ? 100 : 0
  end

  def eval_logged_in
    User.logged_in? ? -50 : 50
  end

  def eval_invalid_encoding
    content = @params[:content].to_s
    !content.respond_to?(:valid_encoding) || content.valid_encoding? ? 0 : 50
  end

  def eval_entropy
    counters = Array.new(256) {0}
    total = 0

    @params[:content].to_s.each_byte do |a|
      counters[a] += 1
      total += 1
    end

    h = 0
    counters.each do |count|
      p  = count.to_f / total
      h -= p * (Math.log(p) / Math.log(2)) if p > 0
    end

    (3 - h) * 50
  end
end

class ::Olelo::Application
  before :edit_buttons, 1000 do
    %{<br/><label for="recaptcha">#{:captcha.t}</label><br/><div id="recaptcha"></div><br/>} if flash[:show_captcha]
  end

  hook :script do
    %{<script type="text/javascript"  src="https://api-secure.recaptcha.net/js/recaptcha_ajax.js"/>
      <script type="text/javascript">
        $(function() {
          Recaptcha.create('#{RECAPTCHA_PUBLIC}',
            'recaptcha', {
              theme: 'clean',
              callback: Recaptcha.focus_response_field
          });
        });
      </script>}.unindent if flash[:show_captcha]
  end

  redefine_method :post_edit do
    if !captcha_valid? && SpamEvaluator.new(params, page).evaluate >= 100
      flash.info! :enter_captcha.t
      flash.now[:show_captcha] = true
      halt render(:edit)
    else
      super()
    end
  end

  private

  def captcha_valid?
    if Time.now.to_i < session[:olelo_antispam_timeout].to_i
      true
    elsif params[:recaptcha_challenge_field] && params[:recaptcha_response_field]
      response = Net::HTTP.post_form(URI.parse('http://api-verify.recaptcha.net/verify'),
                                     'privatekey' => RECAPTCHA_PRIVATE,
                                     'remoteip'   => request.ip,
                                     'challenge'  => params[:recaptcha_challenge_field],
                                     'response'   => params[:recaptcha_response_field])
      if response.body.split("\n").first == 'true'
        session[:olelo_antispam_timeout] = Time.now.to_i + 600
        flash.info! :captcha_valid.t
        true
      else
        flash.error! :captcha_invalid.t
        false
      end
    end
  end
end
