# Requires that a :worker role is defined in your configuration

# TODO: Update template paths

after 'deploy', 'resque:restart'
after 'deploy:migrations', 'resque:restart'

namespace :resque do

  task :restart, roles: :worker, :except => { :no_release => true } do
    run 'sudo monit reload'
    sleep 2
    run "sudo monit -g #{resque_prefix}_resque_workers restart"
    run "sudo monit -g #{resque_prefix}_resque_workers summary"
  end

end

def resque_template(filename, values)
  template = File.open(File.join('templates', filename)).read
  template.gsub(/#\{([^}]+)\}/) { |m| values[$1.to_sym]}
end


def resque_worker_monitd(file, options = {})
  file = "#{file}_#{resque_prefix}"

  mem = options[:totalmem] || '675'

  depends = []
  depends << 'redis'
  depends << options[:depends]
  depends.flatten!
  depends.compact!
  depends = depends.empty? ? '' : "depends on #{depends.join(', ')}"

  script = resque_template('resque_monitd', depends: depends, file: file, current_path: current_path, mem: mem, resque_prefix: resque_prefix)

  put script, "#{current_path}/tmp/#{file}", :mode => 0644
  run "sudo mv #{current_path}/tmp/#{file} /etc/monit.d/#{file}"
  run "sudo chown root:root /etc/monit.d/#{file}"
end


def resque_worker_initd(worker, options = {})

  queue = options[:queue] || worker

  file = "resque_worker"
  file += "_#{resque_prefix}"
  file += "_#{worker}"

  script = resque_template('resque_initd', rvm_path: rvm_path, rvm_ruby_string: rvm_ruby_string, current_path: current_path, rails_env: rails_env, queue: queue, file: file)

  put script, "#{current_path}/tmp/#{file}", :mode => 0755
  run "sudo mv #{current_path}/tmp/#{file} /etc/init.d/#{file}"
  run "sudo chown root:root /etc/init.d/#{file}"
end
