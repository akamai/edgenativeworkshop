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

1. Pull down this repository locally
```
git init && git clone https://github.com/akamai/edgenativeworkshop
```
2. Run the install tools script from the repository to install terraform and ansible
```
cd edgenativeworkshop && ./install-tools.sh
```
3. Add your linode API token and your username (any unique string, remember it for later) to the Terraform variables file
```
echo 'linode_token  = "{token}"' >> terraform.tfvars
```
```
echo 'userid = "{userid}" >> terraform.tfvars
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
1. Run scp to copy the cert keypair files
```
scp workshop@filehost.connected-cloud.io:fullchain.pem .
```
```
scp workshop@filehost.connected-cloud.io:privkey.pem .
```
### Use Ansible to install NATS.io and start your distributed NATS cluster
1. Once the instances are created, use Terraform output to generate ansible inventory files
```
terraform output ip_address | sed -n 's/^.*"\([0-9.]*\)".*$/\1/p' > ansible.inv
```
```
terraform output jp_osa_ip_address | sed -n 's/^.*"\([0-9.]*\)".*$/\1/p' > osaka.inv
```
2. Run the included script to generate a nats config file based on the IP addresses of the hosts
```
./nats_config.sh
```
3. Copy the keys to the cluster nodes
```
export ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook -i ansible.inv copykeys.yml
```
4. Setup and run the NATS.io cluster
```
ansible-playbook -i ansible.inv nats-setup.yml
```
### Install the Microservices layer 

1. Use the docker Ansible playbook to install Docker on the cluster nodes
```
ansible-playbook -i ansible.inv docker.yml
```
2. Run the redis-nats connector in the Osaka compute region
```
ansible-playbook -i osaka.inv start-redis-nats.yml
```
3. Start the app layer in docker
```
ansible-playbook -i ansible.inv start-app.yml
```
### Generate Terraform Scripts for Akamai Global Traffic Management 
1. Run the gtm.sh script to generate a Terraform config file for Global Traffic Management
```
./gtm.sh --user={username}
```
2. Copy the terraform file to the filehost machine
```
scp {username}.tf workshop@filehost.connected-cloud.io:.
```
### Cleanup and destroy the environment after the workshop is done
1. Delete the generated terraform file for GTM (this will collidate with the IAAS terraform state if not deleted)
```
rm {username}.tf
```
2. Use Terraform to delete the workshop virtual machines
```
terraform destroy
```
## Integration with Akamai Services
### Global Traffic Management
The Terraform file generated on the last step of the workshop will be applied to an Akamai Demo config by the instructor. The file will generate a GTM property under the connectedcloud5.akadns.net domain, with the property name of {username}, and a GTM DNS name of {username}.connectedcloud5.akadns.net. This name will performance load balance each request, mapping users to the most proximate Compute region with no bias for even load distribution. 

There are two default regions pre-built-
* edgenative.connectedcloud5.akadns.net - uses all four of the workshop regions for distribution.
* legacy.connectedcloud5.akadns.net - uses only one region to simulate a legacy, centralized origin.

### Akamai Ion and WAF
The workshop Akamaized URL is workshop.connected-cloud.io. For the API, Websocket, and Server-Sent Events components of the application, using the origin={username} query string will instruct Ion to use {username}.connectedcloud5.akadns.net as an origin. The HTML components of the application are stored in Object Storage.
### Akamai EdgeWorkers
The Get Quote service within the application uses Akamai EdgeWorkers to execute server-side javascript that calculates option value based on strike price and current price. The Edgeworker request is in the format of /quote?currentPrice=X&strikePrice=Y&optionType={call|put}

For sake of comparision, the same service is running on the application surface at /quoteorigin. This call can be directed to a specific GTM origin as explained above via the origin={{username}|edgenative|legacy} query string argument.
### Observability 
The Ion Property has DataStream2 enabled, and sends complete CDN logs to Hydrolix TrafficPeak. When viewing dashboards in TrafficPeak, of particular interest is changes in Edge Turn-Around Time (measuring origin response latency) as requests switch from using distributed to centralized origins and back.

### Performance Tests
There are two pages that can test in realtime the performance delta between deployment types.
* API Comparison - https://workshop.connected-cloud.io/scoreboard/api-compare.html - this makes an API call to /get?topic=price, and uses the origin query string to direct Akamai to use the edge-native origin vs. the centralized origin, and shows the results on a bar graph.
* Function Comparison - https://workshop.connected-cloud.io/scoreboard/function-compare.html - This runs the Option Pricing function, and directs the call to the Akamai EdgeWorker, as well as to hosted functions on both the edge-native and centralized origin, and shows the response time difference.

Performance data can also be generated by running a distributed locust.io test, as scripted in this repository - https://github.com/ccie7599/locust-edgenative, and viewing the Edge Turn-Around Time panel in TrafficPeak. As scripted, including the /get (for edge-native) or /getlegacy (for centralized) in the path panel filter in TrafficPeak will contrast the turn-around time when using edge-native vs. centralized origins.
