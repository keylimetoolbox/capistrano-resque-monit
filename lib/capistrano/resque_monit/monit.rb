after 'monit:config', 'monit:restart'

namespace :monit do

  task :config, :except => { :no_release => true } do
    run 'sudo chkconfig monit on'
  end

  task :status do
    run 'sudo monit status'
  end

  task :log do
    run 'sudo tail -f /var/log/monit'
  end

  task :start do
    run 'sudo monit start all'
  end

  task :stop do
    run 'sudo monit stop all'
  end

  task :restart, :except => { :no_release => true } do
    run 'sudo monit reload'
    run 'sudo monit summary all'
  end
end

def sed_initd(file, role)
  sed_template "templates/etc/init.d/#{file}", {
      CURRENT: current_path,
      PIDFILE: "tmp/pids/#{file}.pid",
      RAILSENV: rails_env,
      GEMHOME: "#{rvm_path}/gems/#{rvm_ruby_string}",
  }, '/etc/init.d/#{file}'
end

def sed_monitd(file, role)
  sed_template "templates/etc/monit.d/#{file}", {
      HOST: server_name,
      EMAIL: monit_email
  }, '/etc/monit.d/#{file}'
end

def sed_monitrc
  sed_template "templates/monitrc", {
    USER: monit_user,
    PASSWORD: monit_password,
    URL: monit_url
  }, '/etc/monitrc'
  run 'sudo chmod 600 /etc/monitrc'
end

def sed_bin(file, role)
  resque_config = YAML.load_file('config/resque_monit.yml')
  (host, port) = resque_config[rails_env].split ':'
  sed_template "templates/usr/local/bin/#{file}", {
      RESQUE_HOST: host,
      RESQUE_PORT: port
  }, '/usr/local/bin/#{file}'
  run "sudo chmod 755 /usr/local/bin/#{file}"
end

def sed_template file, values, dest
  cmds = values.map { |k, v| "-e 's/%#{k}%/#{v.gsub(%r(/), '\\/')}/g'" }.join ' '
  run "cd #{deploy_to}/current && sudo sed #{cmds} #{file} > #{dest}"
end

