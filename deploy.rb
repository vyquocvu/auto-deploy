set :repo_url, 'git'
set :rails_env, :staging
set :user, 'user'
set :deploy_to, '/home/projects/projecy'
ask :branch, 'staging_vn'

server 'ip', user: 'user', roles: %w{docker}

set :ssh_options, {
keys: %w(~/.ssh/id_rsa),
forward_agent: false, }

namespace :deploy do
 
 task :migration do
  on roles(:docker) do
    execute "cd /home/projects/docker/appr/; docker exec -it app_1 sh -c 'bundle exec rails db:seed RAILS_ENV=#{fetch(:rails_env)}'"
  end
 end

 task :docker_stop do
   on roles(:docker) do
     execute 'cd /home/projects/docker/appr/; docker-compose stop'
   end
 end

 task :docker_start do
   on roles(:docker), wait: 10 do
     execute 'cd /home/projects/docker/appr/; docker-compose up -d'
   end
 end

 task :docker_restart do
   on roles(:docker), wait: 10 do
     execute 'cd /home/projects/docker/appr/; docker-compose restart'
   end
 end

 task :docker_status do
   on roles(:docker), wait: 10 do
     execute 'cd /home/projects/docker/appr/; docker-compose ps'
   end
 end
#  after :publishing, 'deploy:migration'
 after :publishing, 'deploy:docker_stop'
 after :finishing, 'deploy:docker_start'
end
