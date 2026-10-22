# This file ensures the records required to run the application exist in every environment. It must stay safe
# for real data: it never deletes records and never creates sample data. The code is idempotent, so it can be run
# at any time with bin/rails db:seed (or alongside db:setup / db:prepare).
#
# Sample data for development lives in db/seeds/development.rb and is loaded only in development.

# --- Staff user (password is set only on creation; change it after the first login) ---
# In production the initial password comes from ADMIN_PASSWORD; elsewhere it is the temporary "123456".
User.find_or_create_by!(email_address: "lacteosfonquilacpc@gmail.com") do |user|
  user.password =
    if Rails.env.production?
      ENV["ADMIN_PASSWORD"].presence ||
        abort("ADMIN_PASSWORD must be set to create the staff user in production " \
              "(e.g. ADMIN_PASSWORD='...' bin/local-prod setup).")
    else
      "123456"
    end
end

load Rails.root.join("db/seeds/development.rb") if Rails.env.development?
