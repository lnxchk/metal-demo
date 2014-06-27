name "provisioner-base"
description "base role for provisioners"
run_list [
  "recipe[build-essential]",
  "recipe[chef-metal]",
  "recipe[aws-metal]",
  "recipe[docker-demo::install_chef_metal]"
]

default_attributes(
  "build-essential" => {
    "compile_time" => true
  }
)


