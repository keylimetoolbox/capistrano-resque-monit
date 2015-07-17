require 'capistrano/resque_monit'
load File.expand_path('../tasks/monit.rake', __FILE__)
load File.expand_path('../tasks/resque.rake', __FILE__)
