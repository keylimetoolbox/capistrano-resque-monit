namespace :resque do

  desc 'Restart all workers for this application using monit'
  task :restart do
    unless fetch(:no_release, false)
      on roles :worker do
        execute :sudo, 'monit reload'
        sleep 2
        execute :sudo,  "monit -g resque_workers_#{fetch(:resque_application)} restart"
        execute :sudo,  "monit -g resque_workers_#{fetch(:resque_application)} summary"
      end
    end
  end

  desc <<-EOS
    Set up init.d and monit.d files for all resque workers.

    This task does nothing by default. You should define it in your `deploy.rb` and
    configure your workers with `resque_worker_monitd` and `resque_worker_initd`.
  EOS
  task :config_workers do
  end
end

after 'deploy', 'resque:restart'
before 'monit:config', 'resque:config_workers'


namespace :load do
  task :defaults do
    set :resque_application, ->{ fetch(:application) } # Used to namespace the workers; should not contain spaces.
  end
end


def resque_worker_monitd(name, host, options = {})
  file = Capistrano::ResqueMonit.file_name(name)

  mem = options[:totalmem] || '675'

  depends = []
  depends << 'redis'
  depends << options[:depends]
  depends.flatten!
  depends.compact!
  depends = depends.empty? ? '' : "depends on #{depends.join(', ')}"

  script = Capistrano::ResqueMonit.template(
      'resque_monitd',
      depends: depends,
      file: file,
      current_path: current_path,
      mem: mem,
      resque_application: fetch(:resque_application)
  )
  Capistrano::ResqueMonit.put_as_root(script, "/etc/monit.d/#{file}", host, :mode => 0644)
end


def resque_worker_initd(worker, host, options = {})
  queue = options[:queue] || worker
  file = Capistrano::ResqueMonit.file_name(worker)
  script = Capistrano::ResqueMonit.template(
      'resque_initd',
      gem_home: fetch(:gem_home, Capistrano::ResqueMonit.find_gem_home(host)),
      current_path: current_path,
      rails_env: fetch(:rails_env),
      queue: queue,
      file: file
  )
  Capistrano::ResqueMonit.put_as_root(script, "/etc/init.d/#{file}", host, :mode => 0755)
end
