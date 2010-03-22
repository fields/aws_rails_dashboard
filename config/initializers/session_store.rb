# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_aws_management_rails_session',
  :secret      => 'ed35a2537ab39c458f58bdff6795ab6701d6faf7bb6eff2ea3ebf6f88fa241d40a570ee30ad09c4b93169a41fa2050217ef821c74bfbf4e68625ef44e12d73ec'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
