# Estágio de Build - Usa o SDK do .NET 8 para compilar a aplicação
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copia os arquivos de projeto primeiro para otimizar o cache do Docker
COPY ["CrudMotthruApi/CrudMotthruApi.csproj", "CrudMotthruApi/"]
COPY ["CrudMotthruApi.sln", "."]
RUN dotnet restore "CrudMotthruApi/CrudMotthruApi.csproj"

# Copia todo o resto do código-fonte e publica a aplicação
COPY . .
WORKDIR "/src/CrudMotthruApi"
RUN dotnet publish "CrudMotthruApi.csproj" -c Release -o /app/publish /p:UseAppHost=false

# ---

# Estágio de Runtime - Usa a imagem ASP.NET otimizada (e menor) para rodar a aplicação
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime

# Cria um grupo e um usuário com privilégios mínimos
RUN addgroup --system appgroup && adduser --system appuser -G appgroup

WORKDIR /app
COPY --from=build /app/publish .

# Define o proprietário dos arquivos para o novo usuário
RUN chown -R appuser:appgroup .

# Muda para o usuário não-root
USER appuser

# Expõe a porta que o Kestrel (servidor do .NET) usa por padrão dentro do container
EXPOSE 8080

ENTRYPOINT ["dotnet", "CrudMotthruApi.dll"]