class SessionsController < ApplicationController
  skip_before_action :authenticate_api_user!

  def new
    extract_url_to_session

    @login_url = "/login?account=#{Rails.application.secrets.staffomatic_site_url}"
    authenticate if params[:account].present? && !current_user.present?
  end

  def create
    authenticate
  end

  def show
    if response = request.env['omniauth.auth']
      user = User.find_by_provider_and_uid(response["provider"], response["uid"]) || User.create_with_omniauth(response)
      session[:user_id]      = user.id
      session[:access_token] = response["credentials"]["token"]
      session[:refresh_token] = response["credentials"]["refresh_token"]

      # make sure we set token expires at
      if (expires_at = response["credentials"]["expires_at"]).present?
        user.token_expires_at = Time.zone.at(expires_at.to_i)
        user.save
      end

      flash[:notice] = "Logged in"
      redirect_to return_address
    else
      flash[:error] = "Could not log in to Staffomatic app."
      redirect_to :action => 'new'
    end
  end

  protected

  def authenticate
    account_url = sanitize_account_param(params)

    redirect_to return_address and return unless account_url.present?

    if account_url = sanitize_account_param(params)
      # setup redirects and API endpoints
      extract_url_to_session

      # if we have an iframe app, we need to render a page
      # in oder to make an redirect. if not, you can use:
      #   redirect_to "/auth/staffomatic?account=#{account_url}"
      # directly from the controller.
      @redirect_url = "/auth/staffomatic?account=#{account_url}"
      render "/common/iframe_redirect", :format => [:html], layout: false
    else
      redirect_to return_address
    end
  end

  def extract_url_to_session
    if params['account']
      session[:account_subdomain] = params['account'].split('.').first
      session[:account_url] = "#{Rails.application.secrets.staffomatic_api_scheme}://#{params['account']}"
    end

    if params['origin']
      session[:return_to] = params['origin']
    end
  end

  def return_address
    session[:return_to] || root_url
  end

  def sanitize_account_param(params)
    # make suere we get the account
    return nil unless params[:account].present?

    name = params[:account].to_s.strip

    # add staffomatic site url, if not present:
    name += ".#{Rails.application.secrets.staffomatic_site_url}" if !name.include?(Rails.application.secrets.staffomatic_site_url) && !name.include?(".")

    # make suere we replace the sheme
    name.sub!(%r|https?://|, '')
    u = URI("#{Rails.application.secrets.staffomatic_api_scheme}://#{name}")

    # check for valid domain
    regex = Regexp.new(".staffomatic-frontend.dev|.easypepapp.dev|.easypepapp.com|.staffomaticapp.com")
    u.host.match(regex).present? ? u.host : nil
  end

end
