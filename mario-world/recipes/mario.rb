#
# mario.rb
#
# run on provisioner
# creates the mario node

fog_key_pair "mandi_demo_ssh"

machine "mario" do
  recipe "postgresql"
  recipe "mydb"
end

