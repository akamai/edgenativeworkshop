# edgenativeworkshop

![image](https://github.com/user-attachments/assets/8824f9a9-89fb-46ed-9b20-a44b002d3ad8)

## Instructions

1. Pull down this repository locally-
```git init && git clone https://github.com/akamai/edgenativeworkshop```

2. Run the install tools script from the repository to install terraform and ansible
```./edgenativeworkshop/install-tools.sh```

3. Add your linode API token to the Terraform variables file
```echo "linode_token  = {token} >> terraform.tfvars```

4. Create a local RSA keypair
```ssh-keygen -t rsa -b 4096```

5. Run Terraform to create the instances
```cd edgenativeworkshop && terraform init && terraform apply```

6. Once the instances are created, use Terraform output to generate an ansible inventory file
```terraform output ip_address | sed -n 's/^.*"\([0-9.]*\)".*$/\1/p' > ansible.inv```

7. Run the included script to generate a nats config file based on the IP addresses of the hosts
```./edgenativeworkshop/nats_config.sh```

8. Use the included Ansible playbook to setup and start the NATS.io cluster
```export ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook -i ansible.inv nats-setup.yml```

9. Use the docker Ansible playbook to install Docker on the cluster nodes
``````export ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook -i ansible.inv docker.yml```

