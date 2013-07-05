# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Tonglian::Application.initialize!

Tonglian::Application.config.session_store :active_record_store, {
  expire_after: 1.months,
}
