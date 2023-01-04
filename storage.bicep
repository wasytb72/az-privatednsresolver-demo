param location string
param storage_account_name string
param storage_pe_name string
param vnetspokesubnetid string
param privatednszonename string

resource storageaccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storage_account_name
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    publicNetworkAccess: 'Disabled'
    allowCrossTenantReplication: false
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource storagepe 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: storage_pe_name
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${storage_pe_name}-conn'
        properties: {
          privateLinkServiceId: storageaccount.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
    subnet: {
      id: vnetspokesubnetid
    }
  }
}

resource privatednszonerecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${privatednszonename}/${storageaccount.name}'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: storagepe.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]
  }
}
