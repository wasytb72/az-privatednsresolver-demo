# BICEP deploy of Azure DNS Private Resolver
Used BICEP as a Domain Specific Language (DSL) to deploy a traditional Hub and Spoke architecture using Azure Bastion and Private Link.  Used Private Endpoint to connect to Azure Files storage to prove Conditional Forwarder from on-premises.  In the reverse direction, used a DNS Forwarding Ruleset/ Rule to forward myexample.com queries from Azure to on-premises DNS.
<br><br>
Azure DNS Private Resolver provides the glue, with its inbound and outbound endpoints deployed inside of distinct subnets of the Hub VNet.
<br><br>
Note. The deployment assumes an empty Resource Group and provisions a DNS Manager VM, using PowerShell DSC and Custom Script Extension.
<br><br><br>
<img src="https://github.com/wasytb72/az-privatednsresolver-demo/DnsPrivateResolver.jpg">
<br><br>
<h3>Git Clone the repo to your local device</h3>
git clone https://github.com/gamcmaho/dnsresolver.git
<br><br>
Create a new Resource Group in your Subscription for the DNS Private Resolver deployment
<br><br>
az login<br>
az account set -s "&ltsubscription name&gt"<br>
az group create --name "&ltresource group name&gt" --location "&ltlocation&gt"<br><br>
<h3>Deploying the DNS Private Resolver solution</h3>
Change directory to "dnsresolver" and modify the "parameters.json" providing values for:<br><br>
location<br>
storage_account_name<br>
dns_resolver_name<br>
domain_name
<br><br>
Note.  The domain name requires a trailing dot, e.g. myexample.com.
<br><br><br>
Update the resource group name below and deploy.
<br><br>Note.  The BICEP deployment typically takes 5 - 10 minutes max.
<br><br>
az deployment group create -g "&ltresource group name&gt" --template-file "main.bicep" --parameters "parameters.json"
<br><br>
<h3>Configure On-premises DNS</h3>
Azure Bastion to vm-dns<br>
Using DNS Manager,<br><br>
Create a New Zone<br>
Select Primary zone<br>
Select Forward lookup zone<br>
Enter zone name, e.g. myexample.com
<br><br>Note.  This does not require a trailing dot.<br><br>
Select Create a new file with this file name<br>
Select Do not allow dynamic updates<br>
Finish
<br><br>
Create a new Conditional Forwarder<br>
For DNS Domain enter, file.core.windows.net<br>
For IP Address enter, IP address of the Inbound Endpoint of your DNS Private Resolver<br>
<br><br>
Create a new Host (A Record) in the Forward lookup zone<br>
For Name enter, vm-consumer<br>
For IP Address enter, IP Address of the NIC of the vm-consumer<br>
Add Host
<br><br>
<h3>Congratulations, you're up and running with Azure DNS Private Resolver!</h3>
<br>
From the vm-consumer on-premises, you can "nslookup &ltstorageaccountname&gt.file.core.windows.net"
<br><br>
From the vm-spoke in Azure, you can "nslookup vm-consumer.myexample.com"