# resque-monit-capistrano

A set of Capistrano scripts for configuring resque workers to be monitored by monit

## Installation

### Note
This gem requires Capistrano to deploy using `sudo`. This is because are generated and copied to `/usr/local/bin`, `/etc/init.d/` and `/etc/monit.d`.

Add this line to your application's Gemfile:

    gem 'resque-monit-capistrano'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resque-monit-capistrano

## Usage

Set resque prefix for app in `deploy.rb`

    set :resque_prefix 'APP_NAME'

Setup values for monit in `deploy.rb`

    set :monit_user
    set :monit_password
    set :monit_url
    set :monit_email

## Contributing

1. Fork it ( https://github.com/keylimetoolbox/resque-monit-capistrano/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
