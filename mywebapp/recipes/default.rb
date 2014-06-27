#
# Cookbook Name:: mywebapp
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
template "/var/www/index.html" do
  source "index.html.erb"
  owner "root"
  group "root"
  mode 0644
end

