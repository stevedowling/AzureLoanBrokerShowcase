using Azure.Identity;
using Azure.Monitor.OpenTelemetry.Exporter;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using NLog.Extensions.Logging;
using NServiceBus.Extensions.Logging;
using NServiceBus.Logging;
using NServiceBus.Transport;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

namespace CommonConfigurations;

public record Customizations(EndpointConfiguration EndpointConfiguration, RoutingSettings Routing);

public static class SharedConventions
{
    public static HostApplicationBuilder ConfigureAzureNServiceBusEndpoint(this HostApplicationBuilder builder, string endpointName,
        Action<Customizations>? customize = null)
    {
        ConfigureMicrosoftLoggingIntegration();

        var endpointConfiguration = new EndpointConfiguration(endpointName);

        // Configure Azure Service Bus Transport
        var serviceBusNamespace = Environment.GetEnvironmentVariable("AZURE_SERVICE_BUS_NAMESPACE");

        ArgumentException.ThrowIfNullOrWhiteSpace(serviceBusNamespace);

        // Use custom transport for emulator compatibility
        var transport = new AzureServiceBusTransport(serviceBusNamespace, new DefaultAzureCredential(), TopicTopology.Default)
        {
            TransportTransactionMode = TransportTransactionMode.ReceiveOnly
        };

        var routing = endpointConfiguration.UseTransport(transport);

        // Configure SQL Server Persistence
        var sqlConnectionString = Environment.GetEnvironmentVariable("SQL_CONNECTION_STRING");

        ArgumentException.ThrowIfNullOrWhiteSpace(sqlConnectionString);

        var persistence = endpointConfiguration.UsePersistence<SqlPersistence>();
        persistence.SqlDialect<SqlDialect.MsSqlServer>();
        persistence.ConnectionBuilder(() => new Microsoft.Data.SqlClient.SqlConnection(sqlConnectionString));

        SetCommonEndpointSettings(endpointConfiguration);

        // Endpoint-specific customization
        customize?.Invoke(new Customizations(endpointConfiguration, routing));

        builder.UseNServiceBus(endpointConfiguration);

        var appInsightsFromBuildConnectionString = Environment.GetEnvironmentVariable("APP_INSIGHTS_CONNECTIONSTRING_BUILDER");

        builder.Services.AddOpenTelemetry()
            .ConfigureResource(resourceBuilder => resourceBuilder.AddService(endpointName))
            .WithTracing(traceBuilder =>
            {
                traceBuilder.AddSource("NServiceBus.*")
                    .AddAzureMonitorTraceExporter(o => o.ConnectionString = appInsightsFromBuildConnectionString)
                    .AddConsoleExporter();
            })
            .WithMetrics(metricsBuilder =>
            {
                metricsBuilder.AddMeter("NServiceBus.*")
                    .AddAzureMonitorMetricExporter(o => o.ConnectionString = appInsightsFromBuildConnectionString)
                    .AddConsoleExporter();
            });

        return builder;
    }

    static void SetCommonEndpointSettings(EndpointConfiguration endpointConfiguration)
    {
        // disable diagnostic writer to prevent docker errors
        // in production each container should map a volume to write diagnostic
        endpointConfiguration.CustomDiagnosticsWriter((_, _) => Task.CompletedTask);
        endpointConfiguration.UseSerialization<SystemJsonSerializer>();

        var outboxKeepDedupeMinutesString = Environment.GetEnvironmentVariable("OUTBOX_KEEP_DEDUPE_MINUTES");

        ArgumentException.ThrowIfNullOrWhiteSpace(outboxKeepDedupeMinutesString);

        if (!int.TryParse(outboxKeepDedupeMinutesString, out var outboxKeepDedupeMinutes))
        {
            throw new ArgumentException("OUTBOX_KEEP_DEDUPE_MINUTES must be a valid integer");
        }

        var outboxSettings = endpointConfiguration.EnableOutbox();

        if (outboxKeepDedupeMinutes == 0)
        {
            outboxSettings.DisableCleanup();
        }
        else
        {
            outboxSettings.KeepDeduplicationDataFor(TimeSpan.FromMinutes(outboxKeepDedupeMinutes));
        }

        endpointConfiguration.EnableInstallers();

        var appInsightsConnectionString = Environment.GetEnvironmentVariable("APP_INSIGHTS_CONNECTIONSTRING");

        ArgumentException.ThrowIfNullOrWhiteSpace(appInsightsConnectionString);

        endpointConfiguration.EnableOpenTelemetryMetrics(appInsightsConnectionString);
        endpointConfiguration.EnableOpenTelemetryTracing(appInsightsConnectionString);

        endpointConfiguration.ConnectToServicePlatform(new ServicePlatformConnectionConfiguration
        {
            Heartbeats = new()
            {
                Enabled = true,
                HeartbeatsQueue = "Particular.ServiceControl",
            },
            CustomChecks = new()
            {
                Enabled = true,
                CustomChecksQueue = "Particular.ServiceControl"
            },
            ErrorQueue = "error",
            SagaAudit = new()
            {
                Enabled = true,
                SagaAuditQueue = "audit"
            },
            MessageAudit = new()
            {
                Enabled = true,
                AuditQueue = "audit"
            },
            Metrics = new()
            {
                Enabled = true,
                MetricsQueue = "Particular.Monitoring",
                Interval = TimeSpan.FromSeconds(1)
            }
        });
    }

    static void ConfigureMicrosoftLoggingIntegration()
    {
        // Integrate NServiceBus logging with Microsoft.Extensions.Logging
        var nlog = new NLogLoggerFactory();
        LogManager.UseFactory(new ExtensionsLoggerFactory(nlog));
    }

    public static void DisableRetries(this EndpointConfiguration endpointConfiguration)
    {
        endpointConfiguration.Recoverability()
            .Immediate(customize => customize.NumberOfRetries(0))
            .Delayed(customize => customize.NumberOfRetries(0));
    }
}