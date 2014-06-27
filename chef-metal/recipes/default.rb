#cookbook_file "/tmp/chef-metal-0.9.gem"

#chef_gem 'chef-metal' do
#  source "/tmp/chef-metal-0.9.gem"
#  action :install
#end

chef_gem 'chef-metal'
chef_gem 'chef-metal-fog'


require 'chef_metal'
require 'cheffish'
