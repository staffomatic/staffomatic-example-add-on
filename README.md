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

Copy Over ´.env_example´ to ´.env´ ´$ cp .env_example .env´

  SECRET_KEY_BASE=""
  STAFFOMATIC_SITE_URL=""
  STAFFOMATIC_API_ENDPOINT=""
  STAFFOMATIC_APP_KEY=""
  STAFFOMATIC_APP_SECRET=""
  STAFFOMATIC_API_SCHEME=""

Rename database

    development:
      database: staffomatic_MY-ADDON-NAME_add_on_development
      <<: *defaults

Run Migrations

$ bin/rake db:create; bin/rake db:migrate
