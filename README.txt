
# TODO
* check all the "INSERT"s
* double check that build-essentials is still needed for chef-metal and cheffish
* create an example that builds multiple app stacks with one provisioner and different options

https://github.com/lnxchk/demo.git

Rocking Policy-Based Provisioning with Chef Metal

If you got to see our demo at ChefConf, or have watched the video at (INSERT LINK), you've gotten a look at how powerful policy-based provisioning can be. We've been calling this project "chef-metal" because it *rocks*. 

Policy-based provisioning allows you to specify, in your Chef infrastructure code, how many hosts, and of what type, to run in your infrastructure. Because the code is like any other code you have in Chef, you can make use of any data you have available. If your monitoring system says that your webhosts are using too many resources, Chef can use that information to increase the number of webhosts you have.

Chef metal uses a new resource type, called "machine" to manage these new system resources. Just like any other Chef resource, the machine resource can have a number of different Providers under the covers. The package resource, for example, might use yum, or apt, or a number of other providers to do what you've specified in your recipes. Our current providers for machine include vagrant, AWS, and Digital Ocean. More providers are being added!

Our ChefConf demo illustrated using policy-based provisioning with AWS, but we didn't get to walk you through all of the chewy bits of the code. So let's take a look at what has to be included so you can use chef-metal to work with AWS.

We talked about using a central provisioning server in your infrastructure. This is a special host. It has access to our API keys for AWS, so they only have to be accessible to one type of host. I'm going to set up my keys with chef-vault (https://github.com/Nordstrom/chef-vault), a project from our friends at Nordstrom, so I can control how the keys are accessed. For more information on Vault, check out Joshua Timberman's slide deck (https://speakerdeck.com/jtimberman/chef-vault).

I have a provisioner host in my infrastructure. You can launch this host however you'd like, with the launch GUI, or with "knife ec2 server create", or with the AWS CLI tools... whatever.

My provisioner node is called "provisioner", and I've given it a run_list containing the "provisioner-base" role listed below.

$ knife node show provisioner
Node Name:   provisioner
Environment: _default
FQDN:        ip-172-31-29-191.ec2.internal
IP:          172.31.29.191
Run List:    role[provisioner-base]
Roles:       provisioner-base, base
Recipes:     chef-vault, build-essential, chef-metal, aws-metal, chef-vault::default, build-essential::default, build-essential::_rhel, chef-metal::default, aws-metal::default
Platform:    centos 6.5
Tags:        


You'll need chef-vault installed on your workstation, and your workstation set up to be a client. The setting for this lives in your knife.rb:
  knife[:vault_mode] = 'client'

There is also a chef-vault cookbook that you'll want to have in your provisioner run_list. I add it to my base role so that I can use vault wherever I need it.

  $ cat roles/base.rb
  name "base"
  description "You get a recipe, and you get a recipe..."
  run_list [
    "recipe[chef-vault]"
  ]

The base role is in my provisioner-base role:

  $ cat roles/provisioner-base.rb
  name "provisioner-base"
  description "set up stuff for provisioners"
  run_list [
    "role[base]",
    "recipe[build-essential]",
    "recipe[chef-metal]",
    "recipe[aws-metal]"
  ]
  default_attributes(
    "build-essential=> {
      "compile_time" => true
    }
  )

Now I can create a data_bag for my API keys for AWS:

  $ cat data_bags/aws_secrets/chef.json
  {
    "id": "chef",
    "aws_access_key_id": "BLAHBLAHBLAHKEY",
    "aws_secret_access_key": "WhateversomeJUNK923847923#$%^&"
  }

Ok. Now I want to be able to share my API key with my provisioner, but not with the rest of my infrastructure.  

  knife vault create aws_secrets chef \
  -J data_bags/aws_secrets/chef.json \
  -A lnxchk -S 'role:provisioner-base'

This command will encrypt the "chef" data bag item so it can be unencrypted by the nodes containing the role "provisioner-base" in their run lists. I've made myself an administrator of the data bag as well. 

The next bit is a little convoluted, but we're working on making it easier.  My provisioner needs to have special permission on my chef server organization to create new nodes. To do that, I need to add it to the "admins" group. 

I'm going to use a two-step process to do this, so in case I want to have multiple provisioner hosts in the future, I only have to remember to add them in one place.

(INSERT REAL INSTRUCTIONS HERE)
The first thing I am going to do is add a "provisioners" group to my organization. I'm going to do this on the webui, under the "Administration" tab. Click "groups" and then "create". You can call your group whatever makes sense to you. 

After the group is created, it has to be added to the admins group. On the same page in the webui, click "Groups" and then select "Admins". In the members tab, click "Add" and enter "provisioners" in the box (or whatever you chose as your group name).

Now if I want, say, a different provisioner host for dev, qa, and prod environments, I add those hosts to the "provisioners" group, and they will have the permissions they need to create new nodes.

Alright. That's our main bits of housekeeping. On to the exciting part!

I've divided my resources up into different recipes in a way that makes sense to me. I'll walk you through all of them, and you can decide what you want to do in your infrastructure.

If you look at the provisioner-base role above, it's got a couple of new cookbooks in it, chef-metal and aws-metal.  The chef-metal cookbook sets up the things we need on the host for chef-metal to work, and my aws-metal::default recipe sets up my settings for the hosts I want to provision with "machine" resources.

Let's take a look at the chef-metal::default recipe:

  $ cat cookbooks/chef-metal/recipes/default.rb
  chef_gem 'chef-metal'
  chef_gem 'chef-metal-fog'
  require 'chef_metal'
  require 'cheffish'

I'm installing a couple of gems into Chef's embedded ruby, and making sure I require them into my running chef-client. The AWS provisioner uses the familiar fog library to talk to AWS, and there is a provider shipped in its own ruby gem to handle that right now.

Next, here's what I have in my aws-metal::default recipe:

  $ cat cookbooks/aws-metal/recipes/default.rb
  require 'chef-vault'
  require 'chef_metal_fog'

  aws = chef_vault_item('aws_secrets', 'chef')
  with_driver 'fog:AWS', :compute_options => { 
    :aws_access_key_id => aws['aws_access_key_id'], 
    :aws_secret_access_key => aws['aws_secret_access_key']
  } 

  fog_key_pair "mandi_demo_ssh" 

  # initialize provisioner
  with_machine_options :use_private_ip_for_ssh => true, :ssh_username => "root", :bootstrap_options => {
    "image_id" => "ami-8997afe0",
    "flavor_id" => "m1.large",
    "start_timeout" => 15*60,
    "ssh_timeout" => 15*60,
    "create_timeout" => 15*60,
    "key_name" => "mandi_demo_ssh"
  }

I'm using chef-vault to share my API keys, so I have to remember to include it. It also has to be a dependency in my metadata.rb file. The chef-metal cookbook is a dependency, too.

Then I'm pulling in my keys using "chef_vault_item". They are included as part of the "with_driver" section for fog:AWS. 

Next, I choose my ssh key pair. If this key doesn't exist yet in my AWS account, it will be created by theprovisioner and added. It's also stored on the provisioner in /etc/chef/keys, in case I need to get to the hosts via ssh. I can add an existing key if I want to, I just have to add some options to fog_key_pair. If I don't specify a key, chef-metal will create a default key pair called metal-demo. I want to be sure my machines are accessible to me, and that I don't run into an old copy of the demo keys. 

The next section, "with_machine_options", specifies all the interesting bits for my provisioner. My default options here are for the provisioner to use the non-routeable IPs for ssh'ing to hosts, and to log in as root. (It's an example, unclench your jaws, wonks). These options will be used every time the provisioner runs chef-client, because it will log into all the nodes I've told it about with "machine" resources and also run chef-client on them. So these settings are important.

The "bootstrap_options" are only used when it is time to instantiate a new node. In my example, I'm booting all the machines to be the same, but you don't have to; you can specify different settings on the machines themselves. These defaults allow me to leave the settings out later. Notice the last option, "key_name". It is the same as the "fog_key_pair" I used earlier. All machine resources built with these options will use that key.

Finally, I have my recipes that describe my infrastructure using machine resources. I have two: mario.rb and luigi.rb. I'm storing them in a cookbook called mario-world. 

  $ cat cookbooks/mario-world/recipes/mario.rb
  fog_key_pair "mandi_demo_ssh"

  machine "mario" do
    recipe "postgresql"
    recipe "mydb"
  end

  $ cat cookbooks/mario-world/recipes/luigi.rb
  fog_key_pair "mandi_demo_ssh"

  num_webservers = 2
  1.upto(num_webservers) do |i|
    machine "luigi#{i}" do
      recipe "apache"
      recipe "mywebapp"
    end
  end

In these recipes, I make sure to use my specified key. My "mario" node is a single node. It will run two recipes, "postgresql" and "mydb". If there isn't a node named mario in my infrastructure, my provisioner will create one with the options specified in the earlier recipe. The machine's name will be "mario" in both my chef server and in AWS. 

My luigi recipe specifies a variable for the number of luigis. I can define this variable in any number of ways, making it a powerful tool for managing my infrastructure. Just like with my mario node, the provisioner will create luigi nodes in AWS and in my chef server. Their names will be luigi1 and luigi2 in both places. 

With these settings, every time the provisioner node runs chef-client, it will check with your IaaS account and your Chef server to make sure your topology meets what is set out in your recipes. If you also want the provisioner to kick off a chef-client run on the hosts, you can add "action :converge" to the individual machine resources. If you are adding a run_list to the hosts, you'll probably just add your chef-client management recipe there for all your machines.

I've divided all my bits up so I can use them for different purposes. If I wanted to manage multiple application stacks from a single provisioner, I could create a different cookbook for each application stack, and run the recipes on my provisioner. I could include different AWS settings for different machine types as well. 


