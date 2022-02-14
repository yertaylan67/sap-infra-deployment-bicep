@description('Virtual Network Resource Group')
param virtualNetworkName_rg string

@description('Virtual Network')
param virtualNetworkName string

@description('Subnet for SAP Application Layer')
param subnetName_app string

@description('Subnet for SAP Database Layer')
param subnetName_db string

@description('Availability Zone for SAP Application Server')
param availabilityZoneName_app string

@description('Availability Zone for SAP Database Server')
param availabilityZoneName_db string

@description('deploy SAP Application Server')
param deployVirtualMachine_app bool

@allowed([
  'Standard_E4ds_v5'
])
@description('Virtual Machine Type for SAP Application Server')
param virtualMachineSize_app string

@maxLength(13)
@description('Virtual Machine Name for SAP Application Server')
param virtualMachineName_app string

@description('OS Image for SAP Application Server')
param imageReference_app object = {
  publisher: ''
  offer: ''
  sku: ''
  version: ''
}

@description('deploy SAP HANA Database Server')
param deployVirtualMachine_db bool

@allowed([
  'Standard_E32ds_v4'
  'Standard_M32ls'
])
@description('Virtual Machine Type for SAP Database Server')
param virtualMachineSize_db string

@maxLength(13)
@description('Virtual Machine Name for SAP Database Server')
param virtualMachineName_db string

@description('OS Image for SAP Database Server')
param imageReference_db object = {
  publisher: ''
  offer: ''
  sku: ''
  version: ''
}

@description('Disk Encryption Set Resource Group')
param diskEncryptionSetName_rg string

@description('Disk Encryption Set')
param diskEncryptionSetName string

@description('OS Administrator User')
param OSadminUserName string

@description('OS Administrator Password')
@secure()
@minLength(8)
@maxLength(20)
param OSadminPassword string

@minLength(3)
@maxLength(3)
param HANASID string

@minLength(2)
@maxLength(2)
param HANAInstanceNumber string

/* this parameter will be entered manually */
@description('Storage Account with SAP software media')
param SAPMediaStore string

/* this parameter will be entered manually */
@description('Storage Account Resource Group')
param SAPMediaStore_rg string

/* this parameter will be entered manually */
@description('Storage Account Key')
@secure()
param SAPMediaStore_acckey string

/* this parameter will be entered manually */
/* this is the shared access signature of storage account container */
@description('Storage Account Container Shared Access Signature')
@secure()
param SAPMediaStore_sas string

@description('Custom Script Extension script for SAP Application Server')
param csExtension_app_script string

@description('Custom Script Extension script for SAP Database Server')
param csExtension_db_script string

var networkInterfaceName_app = '${virtualMachineName_app}-nic1'
var networkInterfaceName_db = '${virtualMachineName_db}-nic1'
var subnetName_app_resId = resourceId(virtualNetworkName_rg, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName_app)
var subnetName_db_resId = resourceId(virtualNetworkName_rg, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName_db)
var diskEncryptionSetName_resId = resourceId(diskEncryptionSetName_rg, 'Microsoft.Compute/diskEncryptionSets', diskEncryptionSetName)
var SAPMediaStore_container = '${SAPMediaStore_resource.properties.primaryEndpoints.blob}sapautomation'
var diskConfig_app = {
  sap: {
    lun: 0
    name: '${virtualMachineName_app}-sap-01'
    diskSizeGB: 128
    caching: 'ReadOnly'
    writeAcceleratorEnabled: false
    managedDisk: {
      diskEncryptionSet: {
        id: diskEncryptionSetName_resId
      }
    }
  }
}

var diskConfig_db = {
  Standard_E32ds_v4: {
    dataDisks: [
      {
        lun: 0
        name: '${virtualMachineName_db}-sap-01'
        createOption: 'Empty'
        diskSizeGB: 128
        caching: 'ReadOnly'
        writeAcceleratorEnabled: false
        managedDisk: {
          diskEncryptionSet: {
            id: diskEncryptionSetName_resId
          }
        }
      }
      {
        lun: 1
        name: '${virtualMachineName_db}-data-01'
        createOption: 'Empty'
        diskSizeGB: 64
        caching: 'None'
        writeAcceleratorEnabled: false
      }
      {
        lun: 2
        name: '${virtualMachineName_db}-data-02'
        createOption: 'Empty'
        diskSizeGB: 64
        caching: 'None'
        writeAcceleratorEnabled: false
      }
      {
        lun: 3
        name: '${virtualMachineName_db}-data-03'
        createOption: 'Empty'
        diskSizeGB: 64
        caching: 'None'
        writeAcceleratorEnabled: false
      }
      {
        lun: 4
        name: '${virtualMachineName_db}-data-04'
        createOption: 'Empty'
        diskSizeGB: 64
        caching: 'None'
        writeAcceleratorEnabled: false
      }
      {
        lun: 5
        name: '${virtualMachineName_db}-log-01'
        createOption: 'Empty'
        diskSizeGB: 128
        caching: 'None'
        writeAcceleratorEnabled: false
      }
      {
        lun: 6
        name: '${virtualMachineName_db}-log-02'
        createOption: 'Empty'
        diskSizeGB: 128
        caching: 'None'
        writeAcceleratorEnabled: false
      }
      {
        lun: 7
        name: '${virtualMachineName_db}-log-03'
        createOption: 'Empty'
        diskSizeGB: 128
        caching: 'None'
        writeAcceleratorEnabled: false
      }
      {
        lun: 8
        name: '${virtualMachineName_db}-shared-01'
        createOption: 'Empty'
        diskSizeGB: 256
        caching: 'ReadOnly'
        writeAcceleratorEnabled: false
        managedDisk: {
          diskEncryptionSet: {
            id: diskEncryptionSetName_resId
          }
        }
      }
      {
        lun: 9
        name: '${virtualMachineName_db}-backup-01'
        createOption: 'Empty'
        diskSizeGB: 512
        caching: 'ReadOnly'
        writeAcceleratorEnabled: false
        managedDisk: {
          diskEncryptionSet: {
            id: diskEncryptionSetName_resId
          }
        }
      }
    ]
  }
  Standard_M32ls: {
    dataDisks: [
      {
        lun: 0
        name: '${virtualMachineName_db}-sap-01'
        createOption: 'Empty'
        diskSizeGB: 128
        caching: 'ReadOnly'
        writeAcceleratorEnabled: false
        managedDisk: {
          diskEncryptionSet: {
            id: diskEncryptionSetName_resId
          }
        }
      }
      {
        lun: 1
        name: '${virtualMachineName_db}-data-01'
        createOption: 'Empty'
        diskSizeGB: 64
        caching: 'None'
        writeAcceleratorEnabled: false
      }
      {
        lun: 2
        name: '${virtualMachineName_db}-data-02'
        createOption: 'Empty'
        diskSizeGB: 64
        caching: 'None'
        writeAcceleratorEnabled: false
      }
      {
        lun: 3
        name: '${virtualMachineName_db}-data-03'
        createOption: 'Empty'
        diskSizeGB: 64
        caching: 'None'
        writeAcceleratorEnabled: false
      }
      {
        lun: 4
        name: '${virtualMachineName_db}-data-04'
        createOption: 'Empty'
        diskSizeGB: 64
        caching: 'None'
        writeAcceleratorEnabled: false
      }
      {
        lun: 5
        name: '${virtualMachineName_db}-log-01'
        createOption: 'Empty'
        diskSizeGB: 128
        caching: 'None'
        writeAcceleratorEnabled: true
      }
      {
        lun: 6
        name: '${virtualMachineName_db}-log-02'
        createOption: 'Empty'
        diskSizeGB: 128
        caching: 'None'
        writeAcceleratorEnabled: true
      }
      {
        lun: 7
        name: '${virtualMachineName_db}-log-03'
        createOption: 'Empty'
        diskSizeGB: 128
        caching: 'None'
        writeAcceleratorEnabled: true
      }
      {
        lun: 8
        name: '${virtualMachineName_db}-shared-01'
        createOption: 'Empty'
        diskSizeGB: 256
        caching: 'ReadOnly'
        writeAcceleratorEnabled: false
        managedDisk: {
          diskEncryptionSet: {
            id: diskEncryptionSetName_resId
          }
        }
      }
      {
        lun: 9
        name: '${virtualMachineName_db}-backup-01'
        createOption: 'Empty'
        diskSizeGB: 512
        caching: 'ReadOnly'
        writeAcceleratorEnabled: false
        managedDisk: {
          diskEncryptionSet: {
            id: diskEncryptionSetName_resId
          }
        }
      }
    ]
  }
}

var csExtension_app = {
  script: '/scripts/${csExtension_app_script}'
  command: 'sh ${csExtension_app_script}'
  arguments: ''
}

var csExtension_db = {
  script: '/scripts/${csExtension_db_script}'
  command: 'sh ${csExtension_db_script}'
  arguments: '"${HANASID}" "${HANAInstanceNumber}" "${SAPMediaStore_container}" "${SAPMediaStore_sas}" "${OSadminUserName}" "${OSadminPassword}"'
}

/* use an existing proximity placement group */
/*
resource proximityPlacementGroup_resource 'Microsoft.Compute/proximityPlacementGroups@2021-07-01' existing = {
  name: proximityPlacementGroupName
}
*/

/* create a new proximity placement group */
/*
resource proximityPlacementGroup_resource 'Microsoft.Compute/proximityPlacementGroups@2021-07-01' = {
  name: proximityPlacementGroupName
  location: resourceGroup().location
  properties: {
    proximityPlacementGroupType: 'Standard'
  }
}
*/

resource SAPMediaStore_resource 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: SAPMediaStore
  scope: resourceGroup(SAPMediaStore_rg)
}

resource networkInterface_app_resource 'Microsoft.Network/networkInterfaces@2020-05-01' = if (deployVirtualMachine_app) {
  name: networkInterfaceName_app
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetName_app_resId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
  }
}

resource networkInterface_db_resource 'Microsoft.Network/networkInterfaces@2020-05-01' = if (deployVirtualMachine_db) {
  name: networkInterfaceName_db
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetName_db_resId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
  }
}

resource disk_app_sap_resource 'Microsoft.Compute/disks@2021-04-01' = if (deployVirtualMachine_app) {
  name: diskConfig_app.sap.name
  location: resourceGroup().location
  sku: {
    name: 'Premium_LRS'
  }
  properties: {
    networkAccessPolicy: 'DenyAll'
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: diskConfig_app.sap.diskSizeGB
    encryption: {
      diskEncryptionSetId: diskEncryptionSetName_resId
      type: 'EncryptionAtRestWithCustomerKey'
    }
  }
  zones: [
    availabilityZoneName_app
  ]
}

resource virtualMachine_app_resource 'Microsoft.Compute/virtualMachines@2019-07-01' = if (deployVirtualMachine_app) {
  name: virtualMachineName_app
  location: resourceGroup().location
  properties: {
    /*
    proximityPlacementGroup: {
      id: proximityPlacementGroup_resource.id
    }
*/
    hardwareProfile: {
      vmSize: virtualMachineSize_app
    }
    osProfile: {
      computerName: virtualMachineName_app
      adminUsername: OSadminUserName
      adminPassword: OSadminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
      }
      allowExtensionOperations: true
    }
    storageProfile: {
      imageReference: {
        publisher: imageReference_app.publisher
        offer: imageReference_app.offer
        sku: imageReference_app.sku
        version: imageReference_app.version
      }
      osDisk: {
        osType: 'Linux'
        name: '${virtualMachineName_app}-os-01'
        createOption: 'FromImage'
        managedDisk: {
          diskEncryptionSet: {
            id: diskEncryptionSetName_resId
          }
        }
      }
      dataDisks: [
        {
          lun: diskConfig_app.sap.lun
          managedDisk: {
            id: disk_app_sap_resource.id
          }
          createOption: 'Attach'
          caching: diskConfig_app.sap.caching
          writeAcceleratorEnabled: diskConfig_app.sap.writeAcceleratorEnabled
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface_app_resource.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
  zones: [
    availabilityZoneName_app
  ]
}

resource virtualMachine_app_extension_resource 'Microsoft.Compute/virtualMachines/Extensions@2021-07-01' = if (deployVirtualMachine_app) {
  name: '${virtualMachine_app_resource.name}/${virtualMachineName_app}-sapapp-deployment'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${SAPMediaStore_container}${csExtension_app.script}'
      ]
    }
    protectedSettings: {
      storageAccountName: SAPMediaStore
      storageAccountKey: SAPMediaStore_acckey
      commandToExecute: '${csExtension_app.command} ${csExtension_app.arguments}'
    }
  }
}

resource virtualMachine_db_resource 'Microsoft.Compute/virtualMachines@2019-07-01' = if (deployVirtualMachine_db) {
  name: virtualMachineName_db
  location: resourceGroup().location
  properties: {
    /*
    proximityPlacementGroup: {
      id: proximityPlacementGroup_resource.id
    }
*/
    hardwareProfile: {
      vmSize: virtualMachineSize_db
    }
    osProfile: {
      computerName: virtualMachineName_db
      adminUsername: OSadminUserName
      adminPassword: OSadminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
      }
      allowExtensionOperations: true
    }
    storageProfile: {
      imageReference: {
        publisher: imageReference_db.publisher
        offer: imageReference_db.offer
        sku: imageReference_db.sku
        version: imageReference_db.version
      }
      osDisk: {
        osType: 'Linux'
        name: '${virtualMachineName_db}-os-01'
        createOption: 'FromImage'
        managedDisk: {
          diskEncryptionSet: {
            id: diskEncryptionSetName_resId
          }
        }
      }
      dataDisks: diskConfig_db[virtualMachineSize_db].dataDisks
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface_db_resource.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
  zones: [
    availabilityZoneName_db
  ]
}

resource virtualMachine_db_extension_resource 'Microsoft.Compute/virtualMachines/Extensions@2021-07-01' = if (deployVirtualMachine_db) {
  name: '${virtualMachine_db_resource.name}/${virtualMachineName_db}-sapdb-deployment'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${SAPMediaStore_container}${csExtension_db.script}'
      ]
    }
    protectedSettings: {
      storageAccountName: SAPMediaStore
      storageAccountKey: SAPMediaStore_acckey
      commandToExecute: '${csExtension_db.command} ${csExtension_db.arguments}'
    }
  }
}
