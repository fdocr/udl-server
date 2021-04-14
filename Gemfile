# coding: utf-8

git_source(:github) { |name| "https://github.com/#{name}.git" }
source "https://rubygems.org"
ruby File.read(File.join(File.dirname(__FILE__), ".ruby-version")).strip

gem 'sinatra', '~> 2.1'
gem 'puma', '~> 5.2', '>= 5.2.2'

group :test, :development do
  gem 'sinatra-reloader', '~> 1.0'
  gem 'dotenv', '~> 2.7', '>= 2.7.6'
end
