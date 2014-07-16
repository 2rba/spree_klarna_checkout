# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_klarna_checkout'
  s.version     = '2.1.3'
  s.summary     = %q{Klarna Checkout based on Klarna API 2.0 for Spree Commerce}
  s.description = s.summary
  s.required_ruby_version = '>= 1.9.3'

  s.author    = 'Serg Tyatin'
  s.email     = '700@2rba.com'
  s.homepage  = 'https://github.com/2rba/spree_klarna_checkout'

  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency "faraday"
  s.add_dependency 'spree_core', '> 2.1.3'
  s.add_development_dependency 'capybara', '~> 2.1'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl', '~> 4.2'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails',  '~> 2.13'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
end
