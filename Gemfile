source 'https://rubygems.org'

gem 'bundler'
gem 'bundler-unload'
gem 'json'
gem 'json_pure'
gem 'minitest'
gem 'puppet'
gem 'rake'
gem 'rdoc'
gem 'rgen'
gem 'highline'
gem 'net-scp'
gem 'net-ssh'
gem 'colorize'
gem 'r10k'

group :production do
  gem 'facter'
  gem 'hiera'
  gem 'hiera-gpg'
end

group :test do
  gem 'ci_reporter'
  gem 'fuubar'
  gem 'puppet-lint', :git => 'https://github.com/rodjek/puppet-lint.git', :branch => 'master'
  gem 'puppetlabs_spec_helper'
  gem 'rspec'
  gem 'rspec-hiera-puppet'
  gem 'rspec-puppet'
  gem 'rspec_junit_formatter'
  gem 'test-unit'
  gem "parallel_tests"
end
