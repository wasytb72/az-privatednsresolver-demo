// Deploy:  az deployment group create -g <resource group name> --template-file main.bicep --parameters parameters.json
@secure()
param adminUsername string
@secure()
param adminPassword string

param location string
param modules_url string
param vm_onprem_dns_name string
param vm_onprem_consumer_name string
param vm_spoke_name string
param vm_size string
param vm_onprem_dns_nic_name string
param vm_onprem_consumer_nic_name string
param vm_spoke_nic_name string
param bastion_name string
param bastion_pip_name string
param storage_account_name string

param vnet_hub_name string
param vnet_hub_cidr string
param bastion_subnet_cidr string
param inbound_resolver_subnet_name string
param inbound_resolver_subnet_cidr string
param outbound_resolver_subnet_name string
param outbound_resolver_subnet_cidr string

param vnet_onprem_name string
param vnet_onprem_cidr string
param dns_subnet_name string
param dns_subnet_cidr string
param consumer_subnet_name string
param consumer_subnet_cidr string

param vnet_spoke_name string
param vnet_spoke_cidr string
param spoke_subnet_name string
param spoke_subnet_cidr string

param private_dns_zone_name string
param custom_dns_server string
param dns_resolver_name string
param domain_name string

param storagedeploy bool

param dnsproberecord string

var inbound_resolver_name = 'inbound-${dns_resolver_name}'
var outbound_resolver_name = 'outbound-${dns_resolver_name}'
var ruleset_name = 'ruleset-${dns_resolver_name}'
var rule_name = 'rule-${dns_resolver_name}'
var ruleset_vnetlink_name = 'vnet-link-${ruleset_name}'
var storage_pe_name = 'pe-${storage_account_name}'

resource privatednszone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: private_dns_zone_name
  location: 'global'
  properties: {}
}

resource bastionpip 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: bastion_pip_name
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource vmonpremdns 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vm_onprem_dns_name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vm_size
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-datacenter-gensecond'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: '${vm_onprem_dns_name}_osdisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        deleteOption: 'Delete'
        diskSizeGB: 127
      }
    }
    osProfile: {
      computerName: vm_onprem_dns_name
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: false
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmonpremdnsnic.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
  }
}

resource vmonpremconsumer 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vm_onprem_consumer_name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vm_size
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-datacenter-gensecond'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: '${vm_onprem_consumer_name}_osdisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        deleteOption: 'Delete'
        diskSizeGB: 127
      }
    }
    osProfile: {
      computerName: vm_onprem_consumer_name
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: false
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmonpremconsumernic.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
  }
  dependsOn: [
    customdns
  ]
}

resource vmspoke 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vm_spoke_name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vm_size
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-datacenter-gensecond'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: '${vm_spoke_name}_osdisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        deleteOption: 'Delete'
        diskSizeGB: 127
      }
    }
    osProfile: {
      computerName: vm_spoke_name
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: false
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmspokenic.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
  }
}

resource deploydns 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  name: '${vm_onprem_dns_name}/Microsoft.Powershell.DSC'
  dependsOn: [
    vmonpremdns
  ]
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: modules_url
      ConfigurationFunction: 'Deploy-DnsManager.ps1\\Deploy-DnsManager'
    }
  }
}

resource vmonpremdnsnic 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: vm_onprem_dns_nic_name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnetonprem.properties.subnets[0].id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}

resource vmonpremconsumernic 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: vm_onprem_consumer_nic_name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnetonprem.properties.subnets[1].id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}

resource vmspokenic 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: vm_spoke_nic_name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnetspoke.properties.subnets[0].id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}


resource bastion 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: bastion_name
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: '${bastion_name}-ipconfig'
        properties: {
          publicIPAddress: {
            id: bastionpip.id
          }
          subnet: {
            id: vnethub.properties.subnets[0].id
          }
        }
      }
    ]
  }
}

resource vnetlinktospoke 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privatednszone.name}/vnet-link-to-spoke'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetspoke.id
    }
    registrationEnabled: false
  }
}

resource vnetlinktohub 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privatednszone.name}/vnet-link-to-hub'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnethub.id
    }
    registrationEnabled: false
  }
  dependsOn: [
    vnetlinktospoke
  ]
}

resource vnetspoke 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnet_spoke_name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_spoke_cidr
      ]
    }
    subnets: [
      {
        name: spoke_subnet_name
        properties: {
          addressPrefix: spoke_subnet_cidr
        }
      }
    ]
  }
}

resource vnethub 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: vnet_hub_name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_hub_cidr
      ]
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastion_subnet_cidr
        }
      }
      {
        name: inbound_resolver_subnet_name
        properties: {
          addressPrefix: inbound_resolver_subnet_cidr
        }
      }
      {
        name: outbound_resolver_subnet_name
        properties: {
          addressPrefix: outbound_resolver_subnet_cidr
        }
      }
    ]
  }
}

resource vnetonprem 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnet_onprem_name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_onprem_cidr
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

resource hubtospokepeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-01-01' = {
  name: '${vnethub.name}/hub-to-spoke-peer'
  properties: {
    remoteVirtualNetwork: {
      id: vnetspoke.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

resource spoketohubpeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-01-01' = {
  name: '${vnetspoke.name}/spoke-to-hub-peer'
  properties: {
    remoteVirtualNetwork: {
      id: vnethub.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
  dependsOn: [
    hubtospokepeer
  ]
}

resource hubtoonprempeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-01-01' = {
  name: '${vnethub.name}/hub-to-onprem-peer'
  properties: {
    remoteVirtualNetwork: {
      id: vnetonprem.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

resource onpremtohubpeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-11-01' = {
  name: '${vnetonprem.name}/onprem-to-hub-peer'
  properties: {
    remoteVirtualNetwork: {
      id: vnethub.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
  dependsOn: [
    hubtoonprempeer
  ]
}

module customdns 'customdns.bicep' = {
  name: 'customdns'
  params: {
    location: location
    custom_dns_server: custom_dns_server
    vnet_onprem_name: vnet_onprem_name
    vnet_onprem_cidr: vnet_onprem_cidr
    dns_subnet_name: dns_subnet_name
    dns_subnet_cidr: dns_subnet_cidr
    consumer_subnet_name: consumer_subnet_name
    consumer_subnet_cidr: consumer_subnet_cidr
  }
  dependsOn: [
    deploydns
  ]
}

resource dnsresolver 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  name: dns_resolver_name
  location: location
  properties: {
    virtualNetwork: {
      id: vnethub.id
    }
  }
}

resource dnsresolverinbound 'Microsoft.Network/dnsResolvers/inboundEndpoints@2022-07-01' = {
  parent: dnsresolver
  name: inbound_resolver_name
  location: location
  properties: {
    ipConfigurations: [
      {
        subnet: {
          id: vnethub.properties.subnets[1].id
        }
      }
    ]
  }
}

resource dnsresolveroutbound 'Microsoft.Network/dnsResolvers/outboundEndpoints@2022-07-01' = {
  parent: dnsresolver
  name: outbound_resolver_name
  location: location
  properties: {
    subnet: {
      id: vnethub.properties.subnets[2].id
    }
  }
  dependsOn: [
    dnsresolverinbound
  ]
}

resource ruleset 'Microsoft.Network/dnsForwardingRulesets@2022-07-01' = {
  name: ruleset_name
  location: location
  properties: {
    dnsResolverOutboundEndpoints: [
      {
        id: dnsresolveroutbound.id
      }
    ]
  }
}

resource rulesetvnetlink 'Microsoft.Network/dnsForwardingRulesets/virtualNetworkLinks@2022-07-01' = {
  parent: ruleset
  name: ruleset_vnetlink_name
  properties: {
    virtualNetwork: {
      id: vnetspoke.id
    }
  }
}

resource rules 'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2022-07-01' = {
  name: '${ruleset.name}/${rule_name}'
  properties: {
    domainName: domain_name
    forwardingRuleState: 'Enabled'
    targetDnsServers: [
      {
        ipAddress: custom_dns_server
        port: 53
      }
    ]
  }
}

resource privatednszonerecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${private_dns_zone_name}/probedns'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: dnsproberecord
      }
    ]
  }
}

module storage 'storage.bicep' = if (storagedeploy) {
  name: 'storage-with-privatelink'
  params:{
    location: location
    storage_account_name: storage_account_name
    storage_pe_name: storage_pe_name
    vnetspokesubnetid: vnetspoke.properties.subnets[0].id
    privatednszonename: private_dns_zone_name
  }
}
