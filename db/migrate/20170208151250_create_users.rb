class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :email
      t.string :first_name
      t.string :last_name
      t.string :provider
      t.string :uid
      t.datetime :token_expires_at
    end
  end
end
