# edgenativeworkshop

![image](https://github.com/user-attachments/assets/8824f9a9-89fb-46ed-9b20-a44b002d3ad8)

## Build your Secure Shell Linode

The first step is to create a Linode using the "Secure Your Server" Marketplace image. This will give us a hardened, consistent environment to run our subsequent commands from.

1. Create a Linode account

-   Goto https://login.linode.com/signup

2. Login to Linode Cloud Manager

-   https://login.linode.com/login

3. Select "Create Linode"
4. Select "Marketplace"
5. Click the "Secure Your Server" Marketplace image.
6. Scroll down and complete the following steps:

-   Limited sudo user
-   Sudo password
-   Ssh key
-   No Advanced options are required

7. Select the Ubuntu 22.04 image type for Select an Image
8. Select a Region.
9. Select the Shared CPU 1GB "Nanode" plan.
10. Enter a root password.
11. Click Create Linode.

12. Once your Linode is running, login to it's shell (either using the web-based LISH console from Linode Cloud Manager, or via your SSH client of choice).

## Build your Edge Native Application 

### Pull the repo source and install your tools

1. Pull down this repository locally-
```
git init && git clone https://github.com/akamai/edgenativeworkshop
```
2. Run the install tools script from the repository to install terraform and ansible
```
cd edgenativeworkshop && ./install-tools.sh
```
3. Add your linode API token to the Terraform variables file
```
echo "linode_token  = {token} >> terraform.tfvars
```
4. Configure linode-cli and input your Linode API token
```
linode-cli configure
```
### Create your machines for your distributed cluster via Terraform
1. Create a local RSA keypair
```
ssh-keygen -t rsa -b 4096
```
2. Run Terraform to create the instances
```
terraform init && terraform apply
```
### Copy the certificate keypair from the filehost
1. Run scp to copy the cert keypair files.
```scp workshop@filehost.connected-cloud.io:fullchain.pem . && scp workshop@filehost.connected-cloud.io:privkey.pem```
### Use Ansible to install NATS.io and start your distributed NATS cluster
1. Once the instances are created, use Terraform output to generate an ansible inventory file
```
terraform output ip_address | sed -n 's/^.*"\([0-9.]*\)".*$/\1/p' > ansible.inv
```
2. Run the included script to generate a nats config file based on the IP addresses of the hosts
```
./nats_config.sh
```
3. Use the included Ansible playbook to setup and start the NATS.io cluster
```
export ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook -i ansible.inv nats-setup.yml
```
### Install the Microservices layer 

1. Use the docker Ansible playbook to install Docker on the cluster nodes
```
ansible-playbook -i ansible.inv docker.yml
```
2. Copy the keys to the cluster nodes
```
ansible-playbook -i ansible.inv copykeys.yml
```
3. Start the app layer in docker
```
ansible-playbook -i ansible.inv start-app.yml
```
4. Run the gtm.sh script to generate a terraform config file for Global Traffic Management
```
./gtm.sh
```
