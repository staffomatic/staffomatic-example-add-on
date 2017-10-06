class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  after_action :allow_staffomatic_iframe
  before_filter :redirect_to_https
  before_filter :authenticate_api_user!
  before_action :set_timezone
  before_action :set_locale
  before_action :extract_iframe_params

  rescue_from Staffomatic::Unauthorized do |exception|
    # session[:user_id] = nil
    # session[:access_token] = nil
    query_string = request.query_string
    if query_string
      redirect_to "#{login_url}?#{query_string}", alert: "Access token expired, try signing in again."
    else
      redirect_to login_url, alert: "Access token expired, try signing in again."
    end
  end

  private

  def allow_staffomatic_iframe
    response.headers['X-Frame-Options'] = 'ALLOW-FROM *staffomatic-frontend.dev'
  end

  def extract_iframe_params
    session[:parent_account_url] = "#{Rails.application.secrets.staffomatic_api_scheme}://#{params[:account]}" if params[:account]
    session[:parent_base_path]   = params[:path] if params[:path]
    session[:current_path]       = request.path if request.path
  end

  # TODO: should be location based.
  def set_timezone
    Time.zone = "Europe/Berlin"
  end

  def set_locale
    I18n.locale = (current_api_user.try(:locale) || 'de')
    I18n.locale
  end

  # session[:account_url] = "demo.staffomatic-frontend.dev"
  def account_url
    return unless session[:account_url].present?
    session[:account_url]
  end

  # the oauth2 client
  def oauth2_client
    return false unless account_url
    @_client ||= OAuth2::Client.new(
      Rails.application.secrets.staffomatic_app_key,
      Rails.application.secrets.staffomatic_app_secret,
      site: account_url,
      token_url: "/v3/oauth/token"
    )
  end

  # Returns the Client to access API
  def staffomatic_client
    options = {access_token: session[:access_token]}
    if Rails.env.development?
      options[:api_endpoint] = "http://api.staffomatic-api.dev/v3/#{session[:account_subdomain]}"
    else
      options[:api_endpoint] = "https://api.staffomaticapp.com/v3/#{session[:account_subdomain]}"
    end
    @staffomatic_client ||= Staffomatic::Client.new(options)
  end

  # before_filter method to ensure logged in user
  def authenticate_api_user!
    return true if current_api_user
    raise Staffomatic::Unauthorized
  end

  # find the user
  def current_api_user
    # make sure we always try to refresh the app!
    refresh_token_if_expired!

    # cached user
    return @_current_api_user if @_current_api_user.present?

    # return @_current_api_user
    if staffomatic_client && (@_current_api_user = staffomatic_client_user)
      return @_current_api_user
    else
      return false
    end

    return false
  end
  alias_method :current_user, :current_api_user
  helper_method :current_api_user

  # Returns the reports app User linkd to the api user
  def staffomatic_client_user
    return unless staffomatic_client

    @_staffomatic_client_user ||= begin
      staffomatic_client.user
    rescue Exception => e
      nil
    end
    @_staffomatic_client_user
  end

  def refresh_token_if_expired!(params = {})
    # skip this, if the token is not exprired!
    return unless token_expired?

    # skip it, if we do not have enough info to access API.
    return unless oauth2_client && session[:refresh_token].present? && session[:access_token].present?

    # lets build the token.
    token = OAuth2::AccessToken.new(oauth2_client, session[:access_token], refresh_token: session[:refresh_token])
    begin
      new_token = token.refresh!
      session[:access_token] = new_token.token
      session[:refresh_token] = new_token.refresh_token

      # make suere we update user with new expires data
      user = User.find(session[:user_id]) rescue nil
      if user && (expires_in = new_token.expires_in).present?
        user.token_expires_at = Time.zone.now + expires_in.to_i.seconds
        user.save
      end
    rescue Exception => e
      error = "token.refresh! failse with error: #{e}"
      d{error}
    end

    return unless session[:access_token].present? &&
                    session[:refresh_token].present?
    new_token
  end

  # return true if token is exprired
  def token_expired?
    return true unless session[:user_id].present?

    user = User.find(session[:user_id]) rescue nil
    return true if user.nil?

    user.token_expires_at < Time.zone.now
  end

  def redirect_to_https
    if request.ssl? == false && use_https? == true && !%w{development staging}.include?(Rails.env)
      protocol = request.ssl? ? "http" : "https"
      flash.keep
      redirect_to protocol: "#{protocol}://", status: :moved_permanently
    end
  end
  def use_https?; true; end

end
