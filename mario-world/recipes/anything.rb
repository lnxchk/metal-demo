require 'chef_metal_fog'

fog_key_pair 'my_bootstrap_key'

with_machine_options :bootstrap_options => {
  :key_name => 'my_bootstrap_key',
  :image_id => 'ami-59a4a230',
  :flavor_id => 't1.micro'
}
