FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
ARG TARGETARCH=linux-x64
WORKDIR /src

COPY . .
RUN dotnet publish src/Client -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# Chiseled with ICU support
FROM mcr.microsoft.com/dotnet/runtime:10.0-noble-chiseled-extra AS base
WORKDIR /app
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "Client.dll"]