[server]
${server_public_ip}

[all:children]
server

[all:vars]
ansible_ssh_user=root
ansible_ssh_private_key_file=${ansible_sshkey}
