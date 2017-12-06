# README

# SETUP APP

Clone example app in new folder:

  git clone git@github.com:staffomatic/staffomatic-example-add-on.git staffomatic-MY-ADDON-NAME-add-on

Change Name in config/application.rb

  module StaffomaticExampleAddOn

to:

  module StaffomaticMyAddonNameAddOn

## 1. Create EDITORIAL Add-On

Request Secrets and Integration URL @ https://staffomatic.com

## 2. Setup Secrets/Database

Copy Over ´Application UID´ & `Secret` to ´config/secrets.yml´

    development:
      secret_key_base: ***
      staffomatic_site_url: 'staffomatic-frontend.dev'
      staffomatic_api_endpoint: "http://api.staffomatic-api.dev/v3/demo"
      staffomatic_api_scheme: "http"
      staffomatic_app_key: ****
      staffomatic_app_secret: ****

Rename database

    development:
      database: staffomatic_MY-ADDON-NAME_add_on_development
      <<: *defaults

Run Migrations

$ bin/rake db:create; bin/rake db:migrate
