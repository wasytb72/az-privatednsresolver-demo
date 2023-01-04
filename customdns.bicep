param location string
param custom_dns_server string 
param vnet_onprem_name string
param vnet_onprem_cidr string
param dns_subnet_name string
param dns_subnet_cidr string
param consumer_subnet_name string
param consumer_subnet_cidr string

resource vnetonprem 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnet_onprem_name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_onprem_cidr
      ]
    }
    dhcpOptions: {
      dnsServers: [
        custom_dns_server
      ]
    }
    subnets: [
      {
        name: dns_subnet_name
        properties: {
          addressPrefix: dns_subnet_cidr
        }
      }
      {
        name: consumer_subnet_name
        properties: {
          addressPrefix: consumer_subnet_cidr
        }
      }
    ]
  }
}
