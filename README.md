### Install Terraform and Ansible
Install [Terraform](https://www.terraform.io/downloads.html) and [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installation-guide) on any machine where you run the Terraform executable and Ansible Playbook

### Prepare for API key and ssh key on IBM Cloud
#### [API-key](https://cloud.ibm.com/docs/account?topic=account-userapikey)    
1. Go to _**Manage**_ > _**Access (IAM)**_ > **_API keys_**
2. Click **_Create an IBM Cloud API key_**
3. Enter a name and description for your API key
4. Click **_Create_**
5. Then, click **__Show__** to display the API key. Or, click **_Copy_** to copy and save it for later, or click **_Download_**

#### [SSH Key](https://cloud.ibm.com/docs/ssh-keys?topic=ssh-keys-about-ssh-keys)
##### [Creation of the ssh-key](https://cloud.ibm.com/docs/hp-virtual-servers?topic=hp-virtual-servers-generate_ssh#generating_ssh_command)
1. Generate ssh key on your machine, e.g.: `ssh-keygen -t rsa`.
2. Copy all the content from `.ssh/id_rsa.pub`, which will be used in the Step 6 below.
##### [Add the ssh-key to the VPC Infrastructure](https://cloud.ibm.com/docs/ssh-keys?topic=ssh-keys-adding-an-ssh-key)
1. Click on **_Navigation Menu_**
2. Click on **_VPC Infrastructure_**
3. Click on **_Compute_** > ****SSH Keys****
4. Click on **_Create_**
5. Add ssh key name (e.g.: my-ssh-key), enter the resource group which is assigned to your Cloud account, region, tags, and description
6. Copy the public key and paste it in the **public_key** field(e.g.: contents in ~/.ssh/id_rsa.pub)
7. Click on **_Add SSH Key_**

### Run Terraform
#### Go to terraform/ directory and modify variables.tf
1. Replace <your_api_key> with the value you save in Prepare for the API key step.
2. Replace <your_ssh_key_name> with the ssh key name (e.g.: my-ssh-key) created in the earlier step. If the key is created in a different region other than us-east, you need to modify the values for both **region** and **zone** variables.
3. Replace </path/to/your/private/key> to the ssh private key you created earlier (e.g.: ~/.ssh/id_rsa)

#### Now you are ready to create VPC resources on IBM Cloud using Terraform. In this example, we create a virtual server in a new VPC which is associated with a public ip.
1. First, run "terraform init"
```
% terraform init

Initializing the backend...

Initializing provider plugins...
- Finding ibm-cloud/ibm versions matching "1.32.1"...
- Finding latest version of hashicorp/local...
- Installing ibm-cloud/ibm v1.32.1...
- Installed ibm-cloud/ibm v1.32.1 (self-signed, key ID AAD3B791C49CC253)
- Installing hashicorp/local v2.1.0...
- Installed hashicorp/local v2.1.0 (self-signed, key ID 34365D9472D7468F)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.
```
2. Run "terraform apply -auto-approve" and you should see the following output in the end.
```
terraform apply -auto-approve
ibm_is_vpc.vpc: Creating...
ibm_is_vpc.vpc: Still creating... [10s elapsed]
ibm_is_vpc.vpc: Creation complete after 17s [id=r014-d19a0bf1-e6db-4864-b0f5-f3cfbaa60033]
data.ibm_is_security_group.sg: Reading...
ibm_is_subnet.subnet: Creating...
data.ibm_is_security_group.sg: Read complete after 5s [id=r014-f60ecbbb-3a5b-44f1-97fa-9223275e47e3]
ibm_is_security_group_rule.ingress_ssh_all: Creating...
ibm_is_security_group_rule.ingress_ssh_all: Creation complete after 2s [id=r014-f60ecbbb-3a5b-44f1-97fa-9223275e47e3.r014-c37441e0-4e81-4217-b41d-fdafdbbe3c8a]
ibm_is_subnet.subnet: Still creating... [10s elapsed]
ibm_is_subnet.subnet: Creation complete after 13s [id=0757-9e915c83-6cfb-4f36-90ca-a53ac2c52d00]
ibm_is_instance.server: Creating...
ibm_is_instance.server: Still creating... [10s elapsed]
ibm_is_instance.server: Still creating... [20s elapsed]
ibm_is_instance.server: Still creating... [30s elapsed]
ibm_is_instance.server: Still creating... [40s elapsed]
ibm_is_instance.server: Still creating... [50s elapsed]
ibm_is_instance.server: Creation complete after 51s [id=0757_1e49233a-7a7a-4673-8a6e-1af73e91f35d]
ibm_is_floating_ip.fip: Creating...
ibm_is_floating_ip.fip: Still creating... [10s elapsed]
ibm_is_floating_ip.fip: Creation complete after 12s [id=r014-3d3bb641-e717-425a-a776-f370385ee241]
local_file.inventory: Creating...
local_file.inventory: Creation complete after 0s [id=17a73a129ade3f0d0e321916d87933ee6b65de92]

Apply complete! Resources: 6 added, 0 changed, 0 destroyed..

Outputs:

ssh_command = "ssh -i /Users/hfwen/.ssh/id_rsa root@52.116.123.206"
```
You can use the ssh command provided in the end of the terraform output and log in to the server.
```
% ssh -i /Users/hfwen/.ssh/id_rsa root@52.116.123.206
Last login: Tue Sep 28 10:10:09 2021 from 123.195.32.148
[root@hpc-tutorial-server ~]# which wget
/usr/bin/which: no wget in (/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin)
```

### Run Ansible Playbook
#### Now you want to use Ansible to configure your server. In this example, notice that there is no wget utility installed on the server and we will run Ansible Playbook to install wget using Ansible yum module.

Go to ansible/ directory. You will see a cluster.inventory file already created using the Terraform templatefile function in the earlier step. You can run Ansible playbook using the following command:
```
% ansible-playbook -i cluster.inventory packages.yaml 

PLAY [set up the hosts file] ****************************************************************************************************************

TASK [Gathering Facts] **********************************************************************************************************************
ok: [52.116.123.206]

TASK [Install packages] *********************************************************************************************************************
changed: [52.116.123.206]

PLAY RECAP **********************************************************************************************************************************
52.116.123.206             : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Now login back to the server and you will see wget installed on the server.
```
[FangMBP2020:cloud-experiment/tutorial/terraform] hfwen% ssh -i /Users/hfwen/.ssh/id_rsa root@52.116.123.206
Last login: Tue Sep 28 10:10:09 2021 from 123.195.32.148
[root@hpc-tutorial-server ~]# which wget
/usr/bin/which: no wget in (/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin)
[root@hpc-tutorial-server ~]# which wget
/usr/bin/wget
```

### Clean up VPC resources on IBM Cloud
#### Go back to terraform/ directory when you are ready to clean up resources on IBM Cloud using "terraform destroy" command:
```
% terraform destroy -auto-approve
local_file.inventory: Destroying... [id=17a73a129ade3f0d0e321916d87933ee6b65de92]
local_file.inventory: Destruction complete after 0s
ibm_is_security_group_rule.ingress_ssh_all: Destroying... [id=r014-f60ecbbb-3a5b-44f1-97fa-9223275e47e3.r014-c37441e0-4e81-4217-b41d-fdafdbbe3c8a]
ibm_is_floating_ip.fip: Destroying... [id=r014-3d3bb641-e717-425a-a776-f370385ee241]
ibm_is_security_group_rule.ingress_ssh_all: Destruction complete after 3s
ibm_is_floating_ip.fip: Still destroying... [id=r014-3d3bb641-e717-425a-a776-f370385ee241, 10s elapsed]
ibm_is_floating_ip.fip: Destruction complete after 14s
ibm_is_instance.server: Destroying... [id=0757_1e49233a-7a7a-4673-8a6e-1af73e91f35d]
ibm_is_instance.server: Still destroying... [id=0757_1e49233a-7a7a-4673-8a6e-1af73e91f35d, 10s elapsed]
ibm_is_instance.server: Still destroying... [id=0757_1e49233a-7a7a-4673-8a6e-1af73e91f35d, 20s elapsed]
ibm_is_instance.server: Still destroying... [id=0757_1e49233a-7a7a-4673-8a6e-1af73e91f35d, 30s elapsed]
ibm_is_instance.server: Destruction complete after 35s
ibm_is_subnet.subnet: Destroying... [id=0757-9e915c83-6cfb-4f36-90ca-a53ac2c52d00]
ibm_is_subnet.subnet: Still destroying... [id=0757-9e915c83-6cfb-4f36-90ca-a53ac2c52d00, 10s elapsed]
ibm_is_subnet.subnet: Destruction complete after 15s
ibm_is_vpc.vpc: Destroying... [id=r014-d19a0bf1-e6db-4864-b0f5-f3cfbaa60033]
ibm_is_vpc.vpc: Still destroying... [id=r014-d19a0bf1-e6db-4864-b0f5-f3cfbaa60033, 10s elapsed]
ibm_is_vpc.vpc: Destruction complete after 11s

Destroy complete! Resources: 6 destroyed.
```
