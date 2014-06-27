fog_key_pair "mandi_demo_ssh"

num_webservers = 2
1.upto(num_webservers) do |i|
  machine "luigi#{i}" do
    recipe "apache"
    recipe "mywebapp"
  end
end

