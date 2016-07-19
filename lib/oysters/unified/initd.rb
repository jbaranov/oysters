require 'oysters'
require 'erb'

Oysters.with_configuration do
  namespace :unified do
    namespace :initd do
      # This tasks install/uninstall initd scripts for:
      # - KEWatcher from resque-sliders gem
      # - Resque Scheduler
      # - Unicorn
      [:kewatcher, :resque_scheduler, :unicorn].each do |program|
        namespace "#{program}" do
          #Run this task as a sudo user!
          desc "Install #{program}"
          task :install, roles: :app do
            tmp_config_path = "/tmp/#{program}_initd_script.sh"
            # Remove old tmp config if present
            sudo "rm -f #{tmp_config_path}", pty: true, shell: :bash

            config = File.read(File.expand_path("../scripts/#{program}_initd_script.sh", __FILE__))
            put config, tmp_config_path, shell: :bash

            sudo "cp #{tmp_config_path} /etc/init.d/#{application}_#{program}", pty: true, shell: :bash
            sudo "chmod +x /etc/init.d/#{application}_#{program}", pty: true, shell: :bash
            sudo "chkconfig --add #{application}_#{program}", pty: true, shell: :bash
            run "rm -f #{tmp_config_path}", shell: :bash
          end

          #Run this task as a sudo user!
          desc "Remove #{program} init.d script"
          task :uninstall, roles: :app do
            sudo "chkconfig --del #{application}_#{program}", pty: true, shell: :bash
            sudo "rm -f /etc/init.d/#{application}_#{program}", pty: true, shell: :bash
          end
        end
      end

      # This tasks install/uninstall sysconfig that contains configuration information for:
      # - KEWatcher from resque-sliders gem
      # - Resque Scheduler
      # - Unicorn
      namespace :sysconfig do
        #Run this task as a sudo user!
        desc 'Generate sysconfig used by init.d scripts and put it into /etc/sysconfig'
        task :install, roles: :app do
          tmp_config_path = "/tmp/deployed_application_sysconfig.sh"
          # Remove old tmp config if present
          sudo "rm -f #{tmp_config_path}", pty: true, shell: :bash

          location = File.expand_path('../templates/app_sysconfig.sh.erb', __FILE__)
          config = ERB.new(File.read(location))
          put config.result(binding), tmp_config_path, shell: :bash

          sudo "cp #{tmp_config_path} /etc/sysconfig/deployed_application", pty: true, shell: :bash
          run "rm -f #{tmp_config_path}", shell: :bash
        end

        #Run this task as a sudo user!
        desc 'Remove sysconfig'
        task :uninstall, roles: :app do
          sudo "rm -f /etc/sysconfig/deployed_application", pty: true, shell: :bash
        end
      end

      #Run this task as a sudo user!
      desc "Install all initd scripts(KEWatcher, Unicorn, Scheduler)"
      task :install_all, roles: :app do
        unified.initd.sysconfig.install
        unified.initd.kewatcher.install
        unified.initd.resque_scheduler.install
        unified.initd.unicorn.install
      end

      #Run this task as a sudo user!
      desc "Uninstall all initd scripts(KEWatcher, Unicorn, Scheduler)"
      task :uninstall_all, roles: :app do
        unified.initd.sysconfig.uninstall
        unified.initd.kewatcher.uninstall
        unified.initd.resque_scheduler.uninstall
        unified.initd.unicorn.uninstall
      end
    end
  end
end
