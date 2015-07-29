require "capistrano/resque_monit/version"

module Capistrano
  module ResqueMonit

    def self.root
      @root ||= Gem::Specification.find_by_name('capistrano-resque_monit').gem_dir
    end

    def self.file_name(name)
      "resque_worker_#{fetch(:resque_application)}_#{name}"
    end

    def self.template(filename, values = {})
      template = File.open(File.join(Capistrano::ResqueMonit.root, 'templates', filename)).read
      unless values.empty?
        template.gsub!(/#\{([^}]+)\}/) { values[$1.to_sym] }
      end
      template
    end

    def self.put_as_root(content, destination, host, options = {})
      SSHKit::Coordinator.new(host).each do
        basename ||= File.basename(destination)
        tmp_path = "#{current_path}/tmp/#{basename}"
        upload! StringIO.new(content), tmp_path, options
        execute :sudo, "mv #{tmp_path} #{destination}"
        execute :sudo, "chown root:root #{destination}"
      end
    end

    def self.find_gem_home(host)
      gem_home = nil
      SSHKit::Coordinator.new(host).each do
        within current_path do
          gem_home = capture(:echo, '$GEM_HOME')
        end
      end
      gem_home
    end
  end
end
