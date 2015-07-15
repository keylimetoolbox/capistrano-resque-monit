load 'capistrano/resque_monit/monit'
load 'capistrano/resque_monit/resque'

# TODO: Update templates path to Gem root path

namespace :monit do
  desc 'Set up base files'
  task :setup do
    sed_monitrc
    run "cd #{deploy_to}/current && sudo cp templates/*.conf /etc"
  end

  desc 'Set up init.d and monit.d files for monit'
  task :config_app, :roles => :app, :except => { :no_release => true } do
    sed_monitd 'nginx', :app
  end
end

namespace :resque_monit do
  desc 'Set up init.d and monit.d files for all resque_monit workers'
  task :config_worker, :roles => :worker, :except => { :no_release => true } do
    sed_initd 'resque_scheduler', :worker
    sed_bin 'redis-check-queue', :worker
  end
end
