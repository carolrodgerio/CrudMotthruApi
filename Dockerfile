FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["CrudMotthruApi/CrudMotthruApi.csproj", "CrudMotthruApi/"]
RUN dotnet restore "CrudMotthruApi/CrudMotthruApi.csproj"
COPY . .
WORKDIR "/src/CrudMotthruApi"
RUN dotnet build "CrudMotthruApi.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "CrudMotthruApi.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "CrudMotthruApi.dll"]