directory "#{node.app.web_dir}/htdocs/" do
    owner node.user.name
    group node.user.group
    mode "0777"
    recursive true
end

cieslix_phoenix_default '/usr/local/etc/varnish/default.vcl'
cieslix_phoenix_vars '/usr/local/etc/varnish/vars.vcl'

cieslix_nginx "/etc/nginx/sites-available/#{node.app.name}" do
    # socket "/var/run/php-fpm-www.sock"
    inet_socket "127.0.0.1:8000"
    root "#{node.app.web_dir}/htdocs"
    fastcgi_read_timeout "600"
    # fastcgi_index "index.php"
    index "index.php index.htm index.html"
    fastcgi_param [
        {
            :name => 'SCRIPT_FILENAME',
            :value => '$document_root$fastcgi_script_name',
        },
        {
            :name => 'MAGE_RUN_CODE',
            :value => 'default',
        },
        {
            :name => 'SCRIPT_NAME',
            :value => '$fastcgi_script_name'
        }
    ]
    servers [
        {
            :location => '~ \.php$',
            :port => "8080",
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

package "libvarnishapi-dev" do
    action :install
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
  command "echo 'CREATE DATABASE IF NOT EXISTS #{node.app.name} CHARSET UTF8' | mysql -uroot -p#{node.mariadb.server_root_password}"
end

execute "import database" do
  action :run
  command "mysql -uroot -p#{node.mariadb.server_root_password} #{node.app.name} < #{node.app.import_sql}"
end

execute "rsync magento" do
  action :run
  command "rsync -ra /vagrant/magento/ #{node.app.web_dir}"
end

execute "add write permissions" do
  action :run
  command "chmod a+w #{node.app.web_dir} -R"
end

execute "change owner" do
  action :run
  command "chown #{node.user.name}:#{node.user.group} #{node.app.web_dir} -R"
end

execute "magento varnish enabled" do
  action :run
  command "cd #{node.app.web_dir}/htdocs; ../tools/n98-magerun.phar config:set varnishcache/general/enabled 1"
end

execute "modman deploy" do
  action :run
  command "cd #{node.app.web_dir}/htdocs; ../tools/modman deploy-all --force"
end
