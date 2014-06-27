name "provisioner-base"
description "base role for provisioners"
run_list [
  "role[base]",
  "recipe[build-essential]",
  "recipe[chef-metal]",
  "recipe[aws-metal]"
]

default_attributes(
  "build-essential" => {
    "compile_time" => true
  }
)


