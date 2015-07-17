namespace :monit do
  desc 'Rebuild the monit configurations and reload monit on each server.'
  task :config do
    on roles [:app, :worker] do
      execute :sudo, 'chkconfig monit on'
    end

    unless fetch(:no_release, false)
      on roles [:app, :worker] do |host|
        %w(
            etc/init.d/monit
            etc/monit.d/logging
        ).each do |template|
          content = Capistrano::ResqueMonit.template(template)
          Capistrano::ResqueMonit.put_as_root(content, "/#{template}", host)
        end

        if fetch(:monit_email)
          %w(
              etc/monit.d/alert
              etc/monit.d/mailserver
          ).each do |template|
            content = Capistrano::ResqueMonit.template(
                template,
                EMAIL: fetch(:monit_email),
                MAIL_SERVER: fetch(:monit_email_smtp),
                MAIL_USER: fetch(:monit_email_user),
                MAIL_PASSWORD: fetch(:monit_email_password)
            )
            Capistrano::ResqueMonit.put_as_root(content, "/#{template}", host)
          end
        end
      end

      app_hostname = nil
      on roles :app do |host|
        app_hostname ||= host.hostname

        content = Capistrano::ResqueMonit.template('etc/monit.d/redis')
        Capistrano::ResqueMonit.put_as_root(content, '/etc/monit.d/redis', host)

        content = Capistrano::ResqueMonit.template(
            'etc/monitrc',
            USER: fetch(:monit_user),
            PASSWORD: fetch(:monit_password),
            URL: fetch(:mmonit_url),
        )
        Capistrano::ResqueMonit.put_as_root(content, '/etc/monitrc', host, :mode => 0600)
      end

      on roles :worker do |host|
        file = Capistrano::ResqueMonit.file_name('resque_scheduler')
        script = Capistrano::ResqueMonit.template(
            'etc/init.d/resque_scheduler',
            gem_home: fetch(:gem_home),
            current_path: fetch(:current_path),
            rails_env: fetch(:rails_env),
            file: file
        )
        Capistrano::ResqueMonit.put_as_root(script, "/etc/init.d/#{file}", host, :mode => 0755)
        resque_worker_monitd 'resque_scheduler', host

        content = Capistrano::ResqueMonit.template(
            'usr/local/bin/redis-check-queue',
            RESQUE_HOST: fetch(:resque_redis_host, app_hostname),
            RESQUE_PORT: fetch(:resque_redis_port)
        )
        Capistrano::ResqueMonit.put_as_root(content, '/usr/local/bin/redis-check-queue', host, :mode => 0755)
      end
    end
  end

  desc 'Get verbose status of monitored processes from monit.'
  task :status do
    on roles [:app, :worker] do
      execute :sudo, 'monit status'
    end
  end

  desc 'Get a streaming log of monit activity from all servers.'
  task :log do
    on roles [:app, :worker] do
      execute :sudo, 'tail -f /var/log/monit'
    end
  end

  desc 'Start all monit processes on all servers.'
  task :start do
    on roles [:app, :worker] do
      execute :sudo, 'monit start all'
    end
  end

  desc 'Stop all monit processes on all servers.'
  task :stop do
    on roles [:app, :worker] do
      execute :sudo, 'monit stop all'
    end
  end

  desc 'Reload monit configuration.'
  task :reload do
    on roles [:app, :worker] do
      execute :sudo, 'monit reload'
      execute :sudo, 'monit summary all'
    end
  end
end

after 'monit:config', 'monit:reload'

namespace :load do
  task :defaults do
    set :monit_user,           ->{ "monit-#{fetch(:application)}" } # Username for connecting to monit on individual servers.
    set :monit_password,       ->{ SecureRandom.hex(8) }            # Email address used to send notifications by monit from individual servers.

    set :monit_email,          ->{ nil }                            # Email address that notifications are sent to by monit from individual servers.
    set :monit_email_user,     ->{ nil }                            # Username to send email notifications from monit.
    set :monit_email_password, ->{ nil }                            # Password to send email notifications from monit.
    set :monit_email_smtp,     ->{ nil }                            # Hostname of the SMTP server to end notifications through.

    set :mmonit_url,           ->{ nil }                            # URL of the M/Monit instance to report up to. Should contain username and password.

    set :resque_redis_host,    -> { nil }                           # Host on which the redis is running for the resque queues.
    set :resque_redis_port,    -> { 6379 }                          # Port redis is running at for resque queues.
  end
end
