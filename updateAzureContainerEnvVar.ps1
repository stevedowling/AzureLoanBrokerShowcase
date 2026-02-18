$apps = az containerapp list --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 | ConvertFrom-Json
foreach ($app in $apps) {
    az containerapp update --name $app.name --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 `
        --set-env-vars "APP_INSIGHTS_CONNECTIONSTRING_BUILDER=InstrumentationKey=9e4b2ba0-c844-4d1b-b32f-ba9897587e98;IngestionEndpoint=https://australiaeast-1.in.applicationinsights.azure.com/;LiveEndpoint=https://australiaeast.livediagnostics.monitor.azure.com/;ApplicationId=a0af7e5d-fca8-4d77-b556-630f4d9a2dd3"
}