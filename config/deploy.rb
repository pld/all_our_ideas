set :keep_releases, 5
set :application,   "compairwise"
set :ip,            ""
set :repository,    ""
set :user,          ''
set :password,      ''
set :scm_username,  ''
set :scm_password,  ''
set :scm,           :subversion
set :monit_group,   ''
set :deploy_to,     ""
set :deploy_via,    :copy

# ssh_options[:port] = 
ssh_options[:paranoid] = false
default_run_options[:pty] = true

task :stage do
  set :deploy_to,  ""
  set :monit_group, ""
  set :repository, ""
end

task :prod do
  set :tag, ""
  set :repository, ""
end

role :web, ip
role :app, ip
role :db, ip, :primary => true

# =============================================================================
# TASKS
after "deploy", "deploy:cleanup"
after "deploy:update_code", "deploy:symlink_configs"

# =============================================================================
namespace :deploy do
  task :symlink_configs, :roles => :app, :except => {:no_symlink => true} do
    run <<-CMD
      cd #{release_path} &&
      ln -nfs #{shared_path}/log #{release_path}/config/log &&
      ln -nfs #{shared_path}/config/mongrel.yml #{release_path}/config/mongrel.yml &&
      ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml &&
      ln -nfs #{shared_path}/admin #{release_path}/public/admin
    CMD
  end

  desc "Restart the Monit processes on the app server by calling monit."
  task :restart, :roles => :app do
    monit.restart
  end
end

namespace :monit do
  desc <<-DESC
  Start Monit processes on the app server.  This uses the :use_sudo variable to determine whether to use sudo or
  not. By default, :use_sudo is set to true.
  DESC
  task :start, :roles => :app do
    sudo "/usr/sbin/monit start all -g #{monit_group}"
  end

  desc <<-DESC
  Restart the Monit processes on the app server by starting and stopping the cluster. This uses the :use_sudo
  variable to determine whether to use sudo or not. By default, :use_sudo is set to true.
  DESC
  task :restart, :roles => :app do
    sudo "/usr/sbin/monit restart all -g #{monit_group}"
  end

  desc <<-DESC
  Stop the Monit processes on the app server.  This uses the :use_sudo
  variable to determine whether to use sudo or not. By default, :use_sudo is
  set to true.
  DESC
  task :stop, :roles => :app do
    sudo "/usr/sbin/monit stop all -g #{monit_group}"
  end
end