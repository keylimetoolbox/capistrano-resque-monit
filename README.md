# capistrano-resque_monit

A set of Capistrano scripts for configuring resque workers to be monitored by monit

> This is compatible with [Capistrano 3](https://github.com/capistrano/capistrano).

> This is compatible with [Resque 1.x](https://github.com/resque/resque/tree/1-x-stable) as the master (2.0 release)
  is still under development and has not been released.

## Installation

> **Note** This gem requires Capistrano to deploy using `sudo`. This is because generated scripts are copied
  to `/usr/local/bin`, `/etc/init.d/` and `/etc/monit.d`.

Add this line to your application's Gemfile:

```ruby
gem 'capistrano-resque_monit'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-resque_monit

## Usage

Add to your `Capfile`:

```ruby
require 'capistrano/resque_monit/tasks'
```

Setup values for monit in `deploy.rb`:

Username and password to access the monit httpd on each server.
If not provided, username defaults to `monit-#{application}` and
a random 8-character password is created (for each deployment).

```ruby
set :monit_user,           ENV['MONIT_USER']
set :monit_password,       ENV['MONIT_PASSWORD']
```

If you are using M/Monit add the URL to the collector. You should include
the username and password in this URL.

```ruby
set :mmonit_url,           ENV['MMONIT_URL']
```

If you want monit on indivudual servers to send you email then set an address
to send those alerts to. You also will need to configure the username,
password, and SMTP server to send that.

```ruby
set :monit_email,          ENV['MONIT_EMAIL_TO']
set :monit_email_user,     ENV['MONIT_EMAIL_USER']
set :monit_email_password, ENV['MONIT_EMAIL_PASSWORD']
set :monit_email_smtp,     ENV['MONIT_EMAIL_SMTP']
```

You can configure the host and port for Redis that has the resque queues. This
defaults to first app server host and 6379, but you may want to change these.

```ruby
set :resque_redis_host,    -> { localhost }
set :resque_redis_port,    -> { 6379 }
```

You can set a namespace for resque jobs. This defaults to your `application` name
(from Capistrano). *This must not contain spaces.*

```ruby
set :resque_application 'APP_NAME'
```

Define a `:worker` role for each environment where the workers will be installed. For example,
you might have separate worker servers in production and run all workers on the app server in staging.

```ruby
# config/deploy/production.rb
server 'app.example.com', user: 'deploy', roles: %w(app web db)
server 'worker1.example.com', user: 'deploy', roles: %w(worker)
server 'worker2.example.com', user: 'deploy', roles: %w(worker)
```

```ruby
# config/deploy/staging.rb
server 'staging.example.com', user: 'deploy', roles: %w(app web db worker)
```

Finally, add a task called `resque:config_workers` to your `deploy.rb` to define the resque queues:

```ruby
namespace :resque do
  task :config_workers do
    unless fetch(:no_release)
      on roles :worker do |host|
        resque_worker_initd  'import', host
        resque_worker_monitd 'import', host 

        resque_worker_initd  'process', host
        resque_worker_monitd 'process', host


        if rails_env == 'production'
          resque_worker_initd  'import2', host, queue: 'import'
          resque_worker_monitd 'import2', host

          resque_worker_initd  'process2', host, queue: 'process'
          resque_worker_monitd 'process2', host
        end
      end
    end
  end
end
```

## Commands

The two commands that you use to define the worker configuration are `resque_worker_initd` and 
`resque_worker_monitd`. 


###`resque_worker_initd`

Creates a file in `/etc/init.d` to start and stop the resque worker.

Each call to this command must have a unique name. You can modify the queue(s) that the worker works from with the
`queue` option.

`queue`:
The name of the queue from which the worker pulls jobs.

This sets the [queue list](https://github.com/resque/resque/tree/1-x-stable#priorities-and-queue-lists) sent to the
worker task, so you can give it a single queue, a comma-separated list of queues, or "*" to process all queues.

If not provided the queue is assumed to match the worker name.

```ruby
resque_worker_initd 'import'
resque_worker_initd 'import2', queue: 'import'
resque_worker_initd 'priorities', queue: 'critical,high,low'
resque_worker_initd 'everything', queue: '*'
```

###`resque_worker_monitd`

Creates a file in `/etc/monit.d` to monitor the resque worker.

There are a number of options you can use to tweak the monit rules:

`totalmem`
Number of MB of memory that monit will allow this worker to consume before recycling it. Default is 675.

`depends`
Other monit processes that this worker depends on. Includes `redis` by default.

You might want this, for example, if you have a worker that uses `resque-scheduler`. In which case you would
include that in the options:

```ruby
resque_worker_monitd 'resque_worker_vacuum', depends: 'resque_scheduler'
```


## Tasks

The following tasks are defined for managing your `monit` and `resque` processes.

### monit:config

Rebuild the monit configurations and reload monit on each server.

### monit:status

Get verbose status of monitored processes from monit.

### monit:log

Get a streaming log of monit activity from all servers.

### monit:start

Start all monit processes on all servers. This will start all monitored processes,
not just the resque jobs managed by this gem.

### monit:stop

Stop all monit processes on all servers. This will stop all monitored processes,
not just the resque jobs managed by this gem.

### monit:reload

Reload monit configuration and display the summary.

### resque:restart

Restart all workers for this application using monit. This only restarts the 
resque workers configured by this gem.


## Contributing

1. Fork it ( https://github.com/keylimetoolbox/capistrano-resque_monit/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
