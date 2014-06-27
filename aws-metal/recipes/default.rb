#
# Cookbook Name:: aws-metal
# Recipe:: default
#
# Copyright 2014, CHEF
#
# All rights reserved - Do Not Redistribute
#
# lnxchk

require 'chef-vault'
require 'chef_metal_fog'

# the data bag item is 
# data_bags/aws_secrets/chef.json
# {
#   "id": "chef",
#   "aws_access_key_id": "whatever",
#   "aws_secret_access_key": "whateverelse"
# }
aws = chef_vault_item('aws_secrets', 'chef')
with_driver 'fog:AWS', :compute_options => { 
  :aws_access_key_id => aws['aws_access_key_id'], 
  :aws_secret_access_key => aws['aws_secret_access_key']
}

fog_key_pair "mandi_demo_ssh" 

with_machine_options :use_private_ip_for_ssh => true, :ssh_username => "root", :bootstrap_options => {
  "image_id" => "ami-8997afe0",
  "flavor_id" => "m1.large",
  "start_timeout" => 15*60,
  "ssh_timeout" => 15*60,
  "create_timeout" => 15*60,
  "key_name" => "mandi_demo_ssh"
}
