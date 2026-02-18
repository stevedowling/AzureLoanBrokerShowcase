# I originally used 'az containerapp compose create' to create the container apps but it didn't work all that well
# and I stopped using it for updates. I used either deployAllContainersToAzureContainerRegistry.ps1 or
# deployToAzure.ps1 for individual apps. I also had to set environment variables manually using
# updateAzureContainerEnvVar.ps1.

Write-Host "Setting environment variables..." -ForegroundColor Cyan

$env:AZURE_SERVICE_BUS_NAMESPACE = "loan-broker.servicebus.windows.net"
$env:CONNECTIONSTRING = "loan-broker.servicebus.windows.net"
$env:SQL_CONNECTION_STRING = "Server=tcp:tf689.database.windows.net,1433;Database=NServiceBus;Authentication=Active Directory Managed Identity;Encrypt=True;"
$env:RAVENDB_CONNECTIONSTRING = "http://servicecontrol-db:8080"
$env:CREDIT_BUREAU_URL = "http://creditbureau:8080/api/score"
$env:TRANSPORTTYPE = "NetStandardAzureServiceBus"
$env:SERVICECONTROL_URL = "http://servicecontrol:33333"
$env:MONITORING_URL = "http://servicecontrol-monitoring:33633"
$env:AZURE_CLIENT_ID = '5c25eb11-dc93-4ef1-8bd8-a129a9d456d1'
$env:APP_INSIGHTS_CONNECTIONSTRING = 'InstrumentationKey=c0e0f8fd-0232-4566-96b6-85d41339dba8;IngestionEndpoint=https://australiaeast-1.in.applicationinsights.azure.com/;LiveEndpoint=https://australiaeast.livediagnostics.monitor.azure.com/;ApplicationId=5aa73658-f68a-40f0-874e-19f248a604ac'
$env:APP_INSIGHTS_CONNECTIONSTRING_BUILDER = 'InstrumentationKey=9e4b2ba0-c844-4d1b-b32f-ba9897587e98;IngestionEndpoint=https://australiaeast-1.in.applicationinsights.azure.com/;LiveEndpoint=https://australiaeast.livediagnostics.monitor.azure.com/;ApplicationId=a0af7e5d-fca8-4d77-b556-630f4d9a2dd3'
$env:PARTICULARSOFTWARE_LICENSE = '<?xml version="1.0" encoding="utf-8"?><license type="Non-Production Development" Applications="All" expiration="2031-12-31" id="1c2ea385-6dc2-4949-a896-e12be1e0c3cd"><name>steve.dowling@particular.net</name><Signature xmlns="http://www.w3.org/2000/09/xmldsig#"><SignedInfo><CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/><SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/><Reference URI=""><Transforms><Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/></Transforms><DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/><DigestValue>WxP4UPpIXqLv2IcgD0kkwA75iM0=</DigestValue></Reference></SignedInfo><SignatureValue>PNxL56fIGVWtRs752XjdzHFMcbPP3/4/2yTBAB4LjbmLbpsbU4FnM2br87jAE/LByyUByHkp4285UZ9UCg9w62HmjOyhVD61dAhGpTduFAP+Z5RQmTLdFt7WsUDwiZt6bZ+gDG6AFOFcQiWZ1/fZ/WIjsbfsxNQ2B91ICDhbuag=</SignatureValue></Signature></license>'
Write-Host "Creating Azure Container Apps from docker-compose-azure.yml..." -ForegroundColor Cyan

$registryPassword = az acr credential show -n tf689registry --query "passwords[0].value" -o tsv

az containerapp compose create `
    --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 `
    --environment LoanBroker `
    --location "Australia East" `
    --registry-server tf689registry.azurecr.io `
    --compose-file-path "./docker-compose-azure.yml" `
    --registry-username tf689registry `
    --registry-password $registryPassword;
#    --env-vars AZURE_SERVICE_BUS_NAMESPACE=loan-broker.servicebus.windows.net `
#        CONNECTIONSTRING=loan-broker.servicebus.windows.net `
#        SQL_CONNECTION_STRING="Server=tcp:tf689.database.windows.net,1433;Database=NServiceBus;Authentication=Active Directory Managed Identity;Encrypt=True;" `
#        RAVENDB_CONNECTIONSTRING=http://servicecontrol-db:8080 `
#        CREDIT_BUREAU_URL=http://creditbureau:8080/api/score `
#        TRANSPORTTYPE=NetStandardAzureServiceBus `
#        SERVICECONTROL_URL=http://servicecontrol:33333 `
#        MONITORING_URL=http://servicecontrol-monitoring:33633 `
#        PARTICULARSOFTWARE_LICENSE=$($env:PARTICULARSOFTWARE_LICENSE) `
#        AZURE_CLIENT_ID=5c25eb11-dc93-4ef1-8bd8-a129a9d456d1

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create Azure Container Apps"
    exit 1
}

exit 1

# Get the FQDNs
Write-Host "Updating Service Pulse connections..." -ForegroundColor Cyan
$serviceControlFqdn = az containerapp show `
    --name servicecontrol `
    --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 `
    --query "properties.configuration.ingress.fqdn" -o tsv

$monitoringFqdn = az containerapp show `
    --name servicecontrol-monitoring `
    --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 `
    --query "properties.configuration.ingress.fqdn" -o tsv

# Update servicepulse environment variables
az containerapp update `
    --name servicepulse `
    --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 `
    --set-env-vars "SERVICECONTROL_URL=https://$serviceControlFqdn/api/" "MONITORING_URL=https://$monitoringFqdn/"


az containerapp identity assign --name creditbureau --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --user-assigned /subscriptions/934f5a76-bd9e-4d9a-be26-94b1476bab33/resourcegroups/tf-cloudxp-sc_cloud_experience-analysis-689/providers/Microsoft.ManagedIdentity/userAssignedIdentities/tf689-user
az containerapp identity assign --name loan-broker --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --user-assigned /subscriptions/934f5a76-bd9e-4d9a-be26-94b1476bab33/resourcegroups/tf-cloudxp-sc_cloud_experience-analysis-689/providers/Microsoft.ManagedIdentity/userAssignedIdentities/tf689-user
az containerapp identity assign --name bank1 --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --user-assigned /subscriptions/934f5a76-bd9e-4d9a-be26-94b1476bab33/resourcegroups/tf-cloudxp-sc_cloud_experience-analysis-689/providers/Microsoft.ManagedIdentity/userAssignedIdentities/tf689-user
az containerapp identity assign --name bank2 --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --user-assigned /subscriptions/934f5a76-bd9e-4d9a-be26-94b1476bab33/resourcegroups/tf-cloudxp-sc_cloud_experience-analysis-689/providers/Microsoft.ManagedIdentity/userAssignedIdentities/tf689-user
az containerapp identity assign --name bank3 --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --user-assigned /subscriptions/934f5a76-bd9e-4d9a-be26-94b1476bab33/resourcegroups/tf-cloudxp-sc_cloud_experience-analysis-689/providers/Microsoft.ManagedIdentity/userAssignedIdentities/tf689-user
az containerapp identity assign --name email-sender --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --user-assigned /subscriptions/934f5a76-bd9e-4d9a-be26-94b1476bab33/resourcegroups/tf-cloudxp-sc_cloud_experience-analysis-689/providers/Microsoft.ManagedIdentity/userAssignedIdentities/tf689-user
az containerapp identity assign --name client --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --user-assigned /subscriptions/934f5a76-bd9e-4d9a-be26-94b1476bab33/resourcegroups/tf-cloudxp-sc_cloud_experience-analysis-689/providers/Microsoft.ManagedIdentity/userAssignedIdentities/tf689-user
az containerapp identity assign --name servicecontrol --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --user-assigned /subscriptions/934f5a76-bd9e-4d9a-be26-94b1476bab33/resourcegroups/tf-cloudxp-sc_cloud_experience-analysis-689/providers/Microsoft.ManagedIdentity/userAssignedIdentities/tf689-user
az containerapp identity assign --name servicecontrol-db --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --user-assigned /subscriptions/934f5a76-bd9e-4d9a-be26-94b1476bab33/resourcegroups/tf-cloudxp-sc_cloud_experience-analysis-689/providers/Microsoft.ManagedIdentity/userAssignedIdentities/tf689-user
az containerapp identity assign --name servicecontrol-audit --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --user-assigned /subscriptions/934f5a76-bd9e-4d9a-be26-94b1476bab33/resourcegroups/tf-cloudxp-sc_cloud_experience-analysis-689/providers/Microsoft.ManagedIdentity/userAssignedIdentities/tf689-user
az containerapp identity assign --name servicecontrol-monitoring --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --user-assigned /subscriptions/934f5a76-bd9e-4d9a-be26-94b1476bab33/resourcegroups/tf-cloudxp-sc_cloud_experience-analysis-689/providers/Microsoft.ManagedIdentity/userAssignedIdentities/tf689-user
az containerapp identity assign --name servicepulse --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --user-assigned /subscriptions/934f5a76-bd9e-4d9a-be26-94b1476bab33/resourcegroups/tf-cloudxp-sc_cloud_experience-analysis-689/providers/Microsoft.ManagedIdentity/userAssignedIdentities/tf689-user


az containerapp update --name creditbureau --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name loan-broker --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name bank1 --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name bank2 --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name bank3 --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name email-sender --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name client --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name servicecontrol --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name servicecontrol-db --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name servicecontrol-audit --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name servicecontrol-monitoring --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name servicepulse --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1


az containerapp update --name creditbureau --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name loan-broker --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name bank1 --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name bank2 --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name bank3 --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name email-sender --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name client --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name servicecontrol --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name servicecontrol-db --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name servicecontrol-audit --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name servicecontrol-monitoring --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1
az containerapp update --name servicepulse --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --min-replicas 1 --max-replicas 1


Write-Host "Deployment completed successfully!" -ForegroundColor Green
