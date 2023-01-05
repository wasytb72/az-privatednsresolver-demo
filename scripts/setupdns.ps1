#Run on the vm-dns
#Create conditional forwarder againt the Resolver DNS Inbound Endpoint
Add-DnsServerConditionalForwarderZone -name "test.contoso.com" -MasterServers 10.0.0.68

#Create authoritative zone contoso.com
Add-DnsServerPrimaryZone -Name "contoso.com"

#create record A probedns.contoso.com with IP 10.3.0.4
Add-DnsServerResourceRecordA -Name probedns -IPv4Address 10.3.0.5 -ZoneName contoso.com