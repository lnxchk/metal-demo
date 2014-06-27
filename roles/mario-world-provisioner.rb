name "mario-world-provisioner"
description "MarioBuilderFactory.class"
run_list [
  "role[provisioner-base]",
  "recipe[mario-world::mario]",
  "recipe[mario-world::luigi]"
]

