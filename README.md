# Azure LoanBroker Showcase (Migrated from AWS)

**Version:** 2.0 - February 2026  
**Status:** ✅ Production Ready on .NET 10

The Azure LoanBroker showcase is a comprehensive loan broker implementation following the [structure presented](https://www.enterpriseintegrationpatterns.com/patterns/messaging/ComposedMessagingExample.html) by [Gregor Hohpe](https://www.enterpriseintegrationpatterns.com/gregor.html) in his [Enterprise Integration Pattern](https://www.enterpriseintegrationpatterns.com/) book.

> [!IMPORTANT]
> **This showcase has been migrated from AWS to Azure services!**
> - ✅ All services run on **.NET 10**
> - ✅ **Real Azure Service Bus** for messaging (requires Azure subscription)
> - ✅ **SQL Server 2022** for persistence (runs locally in Docker)
> - ✅ **Azure Functions** for serverless components (runs locally)
> - ✅ **NServiceBus 10** with Azure transports
> - ⚠️ **Azure Service Bus namespace required** - see setup instructions below

## 🎯 Quick Start

### Prerequisites
1. **Azure Service Bus namespace** (Standard or Premium tier)
   - See [Setup Instructions](#setup-azure-service-bus) below
2. **.NET 10 SDK**
3. **Docker Desktop** (8GB+ RAM recommended)

### Setup Steps

1. **Configure Azure Service Bus connection**
   ```bash
   # Copy the template
   cp env/azure.env.template env/azure.env
   
   # Edit env/azure.env and add your connection string
   # Get it from: Azure Portal > Your Service Bus > Shared access policies > RootManageSharedAccessKey
   ```

2. **Start the application**
   ```bash
   # Windows
   .\start.ps1
   
   # Linux/Mac
   ./start.sh
   
   # Or manually
   docker-compose up -d
   docker-compose up client
   ```

**See [README-SETUP.md](README-SETUP.md) for detailed setup instructions.**

---

## Setup Azure Service Bus

### Create Azure Service Bus Namespace

1. **Sign in to Azure Portal**
   - Go to https://portal.azure.com
   - Sign in with your Azure account

2. **Create a Service Bus Namespace**
   ```bash
   # Using Azure CLI (recommended)
   az login
   az group create --name loan-broker-rg --location eastus
   az servicebus namespace create \
     --resource-group loan-broker-rg \
     --name your-namespace-name \
     --location eastus \
     --sku Standard
   ```
   
   Or via Azure Portal:
   - Search for "Service Bus" in the portal
   - Click "+ Create"
   - Fill in:
     - Resource Group: Create new or use existing
     - Namespace name: Choose a unique name (e.g., `loanbroker-sb-dev`)
     - Location: Choose closest to you
     - Pricing tier: **Standard** or **Premium** (Basic is NOT supported)
   - Click "Review + Create" then "Create"

3. **Get the Connection String**
   - Navigate to your Service Bus namespace
   - Go to "Settings" > "Shared access policies"
   - Click on "RootManageSharedAccessKey"
   - Copy the "Primary Connection String"
   
   It should look like:
   ```
   Endpoint=sb://your-namespace.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=YOUR_KEY_HERE
   ```

4. **Configure the Application**
   ```bash
   # Copy the template
   cp env/azure.env.template env/azure.env
   
   # Edit env/azure.env
   nano env/azure.env  # or use your preferred editor
   
   # Paste your connection string for both variables:
   AZURE_SERVICE_BUS_CONNECTION_STRING=Endpoint=sb://...
   CONNECTIONSTRING=Endpoint=sb://...
   ```

> [!IMPORTANT]
> - Never commit `env/azure.env` to source control (it's in .gitignore)
> - Each developer should set up their own connection string
> - For production, use Azure Managed Identity instead of connection strings

### Alternative: Azure Managed Identity (Production)

For production environments, consider using Azure Managed Identity instead of connection strings for better security.

> [!NOTE]
> The current implementation uses connection strings. To use Managed Identity, you would need to:
> 1. Modify `SharedConventions.cs` to detect when only a namespace is provided (without full connection string)
> 2. Use `new AzureServiceBusTransport(fullyQualifiedNamespace, new DefaultAzureCredential(), TopicTopology.Default)`
> 3. Configure Azure RBAC roles for your application identity
> 
> This is not currently implemented but would be a recommended enhancement for production deployments.

---

This is the logical architecture:

![Logical architecture](https://github.com/user-attachments/assets/5f2ef8b0-c7d4-4cef-ab7b-a8561cbd3282)

And this is how that is represented using Azure services running locally:

![AWS Architectural Diagram](img/architecture-view.png)

## What's in the box

The example is composed by:

- A client application, sending loan requests.
- A credit bureau providing the customers' credit score.
- A loan broker service that receives loan requests enriches them with credit scores and orchestrates communication with downstream banks.
- Three bank adapters, acting like Anti-Corruption layers (ACL), simulate communication with downstream banks offering loans.
- An email sender simulating email communication with customers.

The example also ships the following monitoring services:

- The Particular platform to monitor endpoints, capture and visualize audit messages, and manage failed messages.
- A Prometheus instance to collect, store, and query raw metrics data.
- A Grafana instance with three different metrics dashboards using Prometheus as the data source.
- A Jaeger instance to visualize OpenTelemetry traces.
- OpenTelemetry collector (ADOT) to collect and export metrics and traces to various destinations.

## Requirements

- .NET 10 SDK
- Docker Desktop (8GB+ RAM recommended)
- Docker Compose v2+
- **Azure Service Bus namespace** (Standard or Premium tier)

## How to run the example

> [!IMPORTANT]
> Before running the example, you must configure your Azure Service Bus connection string.
> See the [Setup Azure Service Bus](#setup-azure-service-bus) section above.

The simplest way to run the example is using Docker for both the endpoints and the infrastructure.
The client application, the loan broker service, the e-mail sender, and the bank adapters can be deployed as Docker containers alongside the Particular platform to monitor the system, SQL Server for persistence, and the additional containers needed for enabling OpenTelemetry observability.

### Quick Start

Use the automated startup scripts:

**Windows:**
```powershell
.\start.ps1
```

**Linux/Mac:**
```bash
./start.sh
```

**Or manually:**
To run the complete example in Docker, execute the following command from the root folder:

```shell
docker compose up --build -d
```

> [!TIP]
> Once the project is running, check out the [Things to try](#things-to-try) section.

The above command will build all projects, build container images, deploy them to the local Docker registry, and start them. The Docker Compose command will also run and configure all the additional infrastructural containers.

To stop the running solution and remove all deployed containers. Using a command prompt, execute the following command:

```shell
docker compose down
```

To run the solution without rebuilding container images, execute the following command:

```shell
docker compose up -d
```

> [!TIP]
> For detailed instructions and troubleshooting, see [README-SETUP.md](README-SETUP.md)

### Running endpoints from the IDE

If you prefer to start the endpoints from your IDE to debug the code, execute the following command from a command prompt in the root directory to start the required infrastructure:

```shell
docker compose --profile infrastructure up -d
```

## Things to try

Once the project is running, here are some things to try. (Links are to `localhost` and will only work when the project is running.)

1. Explore some [traces in the Jaeger UI](http://localhost:16686/search?service=LoanBroker).
    * The green circles are traces where the entire flow completed successfully.
    * The red circles are traces that contain an exception at some point. (Bank3 fails 1/3 of the time.) Click into the failed steps and find the exception message and stack trace in the logs.
2. Check out a selection of [business metrics in Grafana](http://localhost:3000/d/edmhjobnxatc0c/loan-broker-demo?orgId=1&refresh=5s&from=now-15m&to=now&timezone=browser). (User `admin` and password `admin`.)
    * Some metrics are available for individual message types, even though the messages are processed from the same message queue.
    * Many more metrics are available by navigating to [Dashboards](http://localhost:3000/dashboards) and selecting a different dashboard.
3. Explore the [ServicePulse endpoint monitoring dashboard](http://localhost:9999/#/monitoring?historyPeriod=1), then navigate to [LoanBroker](http://localhost:9999/#/monitoring/endpoint/LoanBroker?historyPeriod=1) to see how these metrics are available for individual message types as well.
4. Investigate the EmailSender failures (the code is rigged to fail 5% of the time) in the [ServicePulse Failed Messages view](http://localhost:9999/#/failed-messages/failed-message-groups).
    * Navigate into the failed message group, then to an individual message.
    * Click on the tabs to see how the stack trace, message headers, and message body help a developer to troubleshoot and fix [systemic errors](https://particular.net/blog/but-all-my-errors-are-severe).
    * Return to the [failed message groups view](http://localhost:9999/#/failed-messages/failed-message-groups) and request a retry for the entire batch of failed messages.
    * The message handler will still fail 5% of the time. Click into the message group and see if there are any messages showing Retry Failures.

## Monitoring

The example comes with the [Particular platform](https://docs.particular.net/platform/), automatically available as Docker containers.

Monitoring information is available in [ServicePulse](http://localhost:9999).

## Telemetry

NServiceBus supports OpenTelemetry. Starting with NServiceBus 9.1, the following metrics are available:

- `nservicebus.messaging.successes` - Total number of messages processed successfully by the endpoint
- `nservicebus.messaging.fetches` - Total number of messages fetched from the queue by the endpoint
- `nservicebus.messaging.failures` - Total number of messages processed unsuccessfully by the endpoint
- `nservicebus.messaging.handler_time` - The time the user handling code takes to handle a message
- `nservicebus.messaging.processing_time` - The time the endpoint takes to process a message
- `nservicebus.messaging.critical_time` - The time between when a message is sent and when it is fully processed
- `nservicebus.recoverability.immediate` - Total number of immediate retries requested
- `nservicebus.recoverability.delayed` - Total number of delayed retries requested
- `nservicebus.recoverability.error` - Total number of messages sent to the error queue

For more information, refer to the [NServiceBus OpenTelemetry documentation](https://docs.particular.net/nservicebus/operations/opentelemetry).

All endpoints are configured to send OpenTelemetry traces to Jaeger. To visualize traces, open the [Jaeger dashboard](http://localhost:16686).

Similarly, endpoints send metrics to Prometheus. To visualize metrics, open the [Grafana dashboards](http://localhost:3000/dashboards). The default Grafana credentials are:

- Username: `admin`
- Password: `admin`

> [!NOTE]
> Setting a new password can be skipped. When containers are redeployed, the credentials are reset to their default values.

The example deploys two pre-configured Grafana dashboards:

- The [LoanBroker](http://localhost:3000/d/edmhjobnxatc0b/loanbroker?orgId=1&refresh=5s) dashboard shows various metrics about the business endpoints behavior, such as the differences between the services critical, processing, and handling time.
- The [NServiceBus](http://localhost:3000/d/MHqYOIqnz/nservicebus?orgId=1&refresh=5s) dashboard shows the metrics related to message fetches, processing, and failures, grouped by endpoints or message type.

> [!NOTE]
> After running the solution multiple times, it might happen that Grafana suddenly shows random data instead of the expected metrics. To reset dashboards, tear down all containers and delete the `data-grafana` and `data-prometheus` folders from the solution folder. Redeploy the containers.
