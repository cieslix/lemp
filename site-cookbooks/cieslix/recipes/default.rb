directory node.app.web_dir do
  owner node.user.name
  group node.user.group
  mode "0777"
  recursive true
end

cookbook_file "#{node.app.web_dir}/index.php" do
  source "index.php"
  mode "0777"
  owner node.user.name
  group node.user.group
end

# php_fpm_pool "www"

cieslix_nginx "/etc/nginx/sites-available/#{node.app.name}" do
    # socket "/var/run/php-fpm-www.sock"
    inet_socket "127.0.0.1:8000"
    root "#{node.app.web_dir}"
    fastcgi_index "index.php"
    index "index.html index.htm index.php"
    fastcgi_param [
        {
            :name => 'SCRIPT_FILENAME',
            :value => '$document_root$fastcgi_script_name',
        },
        {
            :name => 'SCRIPT_NAME',
            :value => '$fastcgi_script_name'
        }
    ]
    servers [
        {
            :location => '~ \.php$',
            :port => "80",
            :server_name => "#{node.app.name}"
        }
    ]
end

nginx_site "#{node.app.name}" do
    enable "true"
end

php5_fpm_pool "#{node.app.name}" do
    pool_user "www-data"
    pool_group "www-data"
    listen_address "127.0.0.1"
    listen_port 8000
    listen_allowed_clients "127.0.0.1"
    listen_owner "nobody"
    listen_group "nobody"
    listen_mode "0666"
    overwrite true
    action :create
    notifies :restart, "service[#{node[:php_fpm][:package]}]", :delayed
end

execute "apt-get update" do
  action :nothing
  command "apt-get update"
end

execute "apt-get dist-upgrade" do
  action :nothing
  command "apt-get dist-upgrade -f"
end

execute "create database" do
  action :run
  command "echo 'CREATE DATABASE IF NOT EXISTS magento CHARSET UTF8' | mysql -uroot -ppassword"
end
