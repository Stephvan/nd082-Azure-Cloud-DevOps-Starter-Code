# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone this repository

2. Create your infrastructure as code

3. Update this README to reflect how someone would use your code.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions

#### Creating the packer file and building a Linux image

------

Specify the listed JSON key pair in the builders value:

```json
"builders": [{
		"type": "azure-arm",
		"client_id": "your service principal client_id here",
		"client_secret": "your service principal client_secret here",
		"subscription_id": "your subscription_id here",
		"tenant_id": "your tenant_id here",
		"managed_image_resource_group_name": "udacity-rg", #specify name of the resource group where image will be created into
	    "managed_image_name": "MyUbuntuImage", #specifiy the name you want the image to bear
	    "os_type": "Linux", #specify the OS type
	    "image_publisher": "Canonical", #specify the OS image publisher
	    "image_offer": "UbuntuServer", #specify the OS image offer
	    "image_sku": "18.04-LTS", #specify the image_sku
	    "azure_tags": {
		"createdBy": "Stephen"  #specify a tag on the resource
	    },

	    "location": "eastus", #specify the location of the image
	    "vm_size": "Standard_DS2_v2" #specify the vm_size
  }
```

For the credentials, environmental variables could be set in your environment to avoid inputting credentials in the packer file. To create the credentials, follow the step below:

1.

```powershell
   #login to azure
   az login
   
   #Create a resource group in azure
   az group create -n myResourceGroup -l eastus
   
   #create a service principal to get your credentials
   az ad sp create-for-rbac --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"
```



2.

After running the command in line 8 above, the client id, secret and tenant id would be shown. You then copy these values into your file or set them as an environmental variable.



3.

Valid the template and build the image. To validate and build the image, run the command:

```
packer validate server.json
packer build server.json
```

Note: server.json is the name of the packer file I am using. Ensure your are in the directory where this file is located, otherwise, the project would not validate and build.



#### Running the Terraform Template

------

1. Create the main.tf file to hold the main configuration for the deployment. The main.tf file has been created for this project.

2. Define all resources to be deployed. you can look up the [Terraform Azure provider](https://www.terraform.io/docs/providers/azurerm/index.html) for help on how to specify different resources.

3. Once all resources are created, create another file called variables.tf. This file will hold all variables and ensure we adhere to the DRY principle.

4. For this project, the below variable file was set in the variables.tf file:

   ```json
   variable "location" {
     description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
     default = "eastus"
   }
   
   #Default Resource Group
   variable "resource_group_name" {
     description = "The name of the resource group in which the resources will be created"
     default     = "udacity-rg"
   }
   
   #Tags
   variable "tags" {
     type        = map(string)
     description = "A map of the tags to use on the resources that are deployed with this module."
   
     default = {
       createdBy = "Stephen"
     }
   }
   
   variable "prefix" {
     description = "The prefix used for all resources in this example"
     default = "udacity"
   }
   
   variable "nb_instances" {
     description = "Specify the number of vm instances"
     default     = "1"
   }
   ```

   The resource group has been set has “udacity-rg” for deployment of all resources. The tags variable is also set as any resources without tag would be not be created as stated in my Azure policy.

   

   To creates more than one VMs, change the “nb_instances” from “1” to the number of desired VMs.

   

5. Once the main.tf and the variables.tf file is ready, create a solution.plan file in the same directory where all the Terraform files are currently located and run the commands below:

   ```
   terraform plan -out solution.plan #this command shows you what will be deployed in Azure. The output of this file will be written to the solution.plan file if there is no error.
   terraform apply solution.plan 
   ```

### Output

After running the expected command, check that you have an image created in a resource group. Also, all resources specified in the terraform main.tf ought t be created in the resource group specified.



**Packer expected output after running the build command:**

------

azure-arm: output will be in this color.

==> azure-arm: Running builder ...
==> azure-arm: Getting tokens using client secret
==> azure-arm: Getting tokens using client secret
    azure-arm: Creating Azure Resource Manager (ARM) client ...
==> azure-arm: WARNING: Zone resiliency may not be supported in eastus, checkout the docs at https://docs.microsoft.com/en-us/azure/availability-zones/
==> azure-arm: Creating resource group ...
==> azure-arm:  -> ResourceGroupName : 'pkr-Resource-Group-ck5k8q63bp'
==> azure-arm:  -> Location          : 'eastus'
==> azure-arm:  -> Tags              :
==> azure-arm:  ->> createdBy : Stephen
==> azure-arm: Validating deployment template ...
==> azure-arm:  -> ResourceGroupName : 'pkr-Resource-Group-ck5k8q63bp'
==> azure-arm:  -> DeploymentName    : 'pkrdpck5k8q63bp'
==> azure-arm: Deploying deployment template ...
==> azure-arm:  -> ResourceGroupName : 'pkr-Resource-Group-ck5k8q63bp'
==> azure-arm:  -> DeploymentName    : 'pkrdpck5k8q63bp'
==> azure-arm: Getting the VM's IP address ...
==> azure-arm:  -> ResourceGroupName   : 'pkr-Resource-Group-ck5k8q63bp'
==> azure-arm:  -> PublicIPAddressName : 'pkripck5k8q63bp'
==> azure-arm:  -> NicName             : 'pkrnick5k8q63bp'
==> azure-arm:  -> Network Connection  : 'PublicEndpoint'
==> azure-arm:  -> IP Address          : 'xx.xxx.xxx.xx'
==> azure-arm: Waiting for SSH to become available...
==> azure-arm: Connected to SSH!
==> azure-arm: Provisioning with shell script: C:\Users\STEPHE~1\AppData\Local\Temp\packer-shell442458659
==> azure-arm: + echo Hello, World!
==> azure-arm: Querying the machine's properties ...
==> azure-arm:  -> ResourceGroupName : 'pkr-Resource-Group-ck5k8q63bp'
==> azure-arm:  -> ComputeName       : 'pkrvmck5k8q63bp'
==> azure-arm:  -> Managed OS Disk   : '/subscriptions/subscription_id here/resourceGroups/PKR-RESOURCE-GROUP-CK5K8Q63BP/providers/Microsoft.Compute/disks/pkrosck5k8q63bp'
==> azure-arm: Querying the machine's additional disks properties ...
==> azure-arm:  -> ResourceGroupName : 'pkr-Resource-Group-ck5k8q63bp'
==> azure-arm:  -> ComputeName       : 'pkrvmck5k8q63bp'
==> azure-arm: Powering off machine ...
==> azure-arm:  -> ResourceGroupName : 'pkr-Resource-Group-ck5k8q63bp'
==> azure-arm:  -> ComputeName       : 'pkrvmck5k8q63bp'
==> azure-arm: Capturing image ...
==> azure-arm:  -> Compute ResourceGroupName : 'pkr-Resource-Group-ck5k8q63bp'
==> azure-arm:  -> Compute Name              : 'pkrvmck5k8q63bp'
==> azure-arm:  -> Compute Location          : 'eastus'
==> azure-arm:  -> Image ResourceGroupName   : 'udacity-rg'
==> azure-arm:  -> Image Name                : 'MyUbuntuImage'
==> azure-arm:  -> Image Location            : 'eastus'
==> azure-arm: Deleting resource group ...
==> azure-arm:  -> ResourceGroupName : 'pkr-Resource-Group-ck5k8q63bp'
==> azure-arm:
==> azure-arm: The resource group was created by Packer, deleting ...
==> azure-arm: Deleting the temporary OS disk ...
==> azure-arm:  -> OS Disk : skipping, managed disk was used...
==> azure-arm: Deleting the temporary Additional disk ...
==> azure-arm: ERROR: -> ResourceGroupNotFound : Resource group 'pkr-Resource-Group-ck5k8q63bp' could not be found.
==> azure-arm:
**Build 'azure-arm' finished.**

**==> Builds finished. The artifacts of successful builds are:**
**--> azure-arm: Azure.ResourceManagement.VMImage:**

OSType: Linux
ManagedImageResourceGroupName: udacity-rg
ManagedImageName: MyUbuntuImage
ManagedImageId: /subscriptions/subscription_id here/resourceGroups/udacity-rg/providers/Microsoft.Compute/images/MyUbuntuImage
ManagedImageLocation: eastus 



**Terraform expected output after running the plan and apply command:**

------

1. Running the plan command:

   **This plan was saved to: solution.plan**

   **To perform exactly these actions, run the following command to apply:**
       **terraform apply "solution.plan"**

2. Running the apply command:

   **Apply complete! Resources: 1 added, 0 changed, 0 destroyed.**