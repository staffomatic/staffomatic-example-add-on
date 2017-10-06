require 'omniauth/strategies/staffomatic'
# export API_ENDPOINT='http://staffomatic-api.dev/v3/demo'
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :staffomatic,
            Rails.application.secrets.staffomatic_app_key,
            Rails.application.secrets.staffomatic_app_secret,
            setup: lambda {|env|
                        params = Rack::Utils.parse_query(env['QUERY_STRING'])
                        site_url = "#{Rails.application.secrets.staffomatic_api_scheme}://#{params['account']}"
                        env['omniauth.strategy'].options[:development_domain] = Rails.application.secrets.staffomatic_site_url
                        env['omniauth.strategy'].options[:client_options][:site] = site_url
                        env['omniauth.strategy'].options[:client_options][:authorize_params] = {
                          account_subdomain: params['account']
                        }
                      }
end
