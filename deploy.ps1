# ==============================================================================
# SCRIPT DE DEPLOY COMPLETO PARA AZURE (ACR + ACI + POSTGRESQL)
# ==============================================================================

# Limpa a tela
Clear-Host

# --- Etapa 0: EDITE SUAS VARIÁVEIS AQUI ---
# Substitua os valores abaixo pelos seus. Use nomes únicos globalmente no Azure.
$resourceGroupName = "<NOME DO RG>"
$acrName = "<NOME DO ACR>"
$postgresServerName = "<NOME DO SERVER DB>"
$postgresAdminUser = "<NOME DO USUÁRIO>"
$postgresAdminPassword = "<SENHA DO USUÁRIO>"
$location = "brazilsouth"
$dnsNameLabel = "<RÓTULO DNS>"

# --- Fim da Edição ---

try {
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host " Iniciando o Script de Deploy para a Sprint DevOps  " -ForegroundColor Cyan
    Write-Host "======================================================"

    # --- Etapa 1: Login e Configuração do Azure ---
    Write-Host "`n[ETAPA 1/7] Conectando ao Azure..." -ForegroundColor Yellow
    az login
    $subscriptionId = (az account show --query id --output tsv)
    az account set --subscription $subscriptionId
    Write-Host "--> Conectado à assinatura: $subscriptionId" -ForegroundColor Green

    # --- Etapa 2: Criação do Grupo de Recursos ---
    Write-Host "`n[ETAPA 2/7] Criando o Grupo de Recursos '$resourceGroupName'..." -ForegroundColor Yellow
    az group create --name $resourceGroupName --location $location --output none
    Write-Host "--> Grupo de Recursos criado com sucesso." -ForegroundColor Green

    # --- Etapa 3: Criação do Banco de Dados PostgreSQL ---
    Write-Host "`n[ETAPA 3/7] Criando o Servidor PostgreSQL '$postgresServerName'..." -ForegroundColor Yellow
    Write-Host "(Esta etapa pode levar vários minutos...)"
    az postgres flexible-server create `
        --resource-group $resourceGroupName `
        --name $postgresServerName `
        --admin-user $postgresAdminUser `
        --admin-password $postgresAdminPassword `
        --sku-name Standard_B1ms --tier Burstable `
        --public-access 0.0.0.0 --storage-size 32 `
        --version 15 `
        --output none
    Write-Host "--> Servidor PostgreSQL criado." -ForegroundColor Green

    # Adicionando regra de firewall explícita para evitar timeout
    Write-Host "--> Adicionando regra de firewall para permitir todas as conexões..."
    az postgres flexible-server firewall-rule create `
        --resource-group $resourceGroupName `
        --name $postgresServerName `
        --rule-name "AllowAll" `
        --start-ip-address "0.0.0.0" `
        --end-ip-address "255.255.255" `
        --output none
    Write-Host "--> Regra de firewall adicionada." -ForegroundColor Green

    Write-Host "--> Criando o banco de dados 'motodb'..."
    az postgres flexible-server db create `
        --resource-group $resourceGroupName `
        --server-name $postgresServerName `
        --database-name motodb `
        --output none
    Write-Host "--> Banco de dados 'motodb' criado com sucesso." -ForegroundColor Green

    # --- Etapa 4: Criação do Azure Container Registry (ACR) ---
    Write-Host "`n[ETAPA 4/7] Criando o Container Registry '$acrName'..." -ForegroundColor Yellow
    az acr create --resource-group $resourceGroupName --name $acrName --sku Basic --admin-enabled true --output none
    Write-Host "--> ACR criado com sucesso." -ForegroundColor Green

    # --- Etapa 5: Build e Push da Imagem Docker ---
    Write-Host "`n[ETAPA 5/7] Fazendo build e push da imagem Docker..." -ForegroundColor Yellow
    az acr login --name $acrName
    $imageTag = "$($acrName).azurecr.io/motthru-api:v1"

    Write-Host "--> Construindo a imagem: $imageTag"
    docker build -t $imageTag .
    
    Write-Host "--> Enviando a imagem para o ACR..."
    docker push $imageTag
    Write-Host "--> Imagem enviada com sucesso." -ForegroundColor Green

    # --- Etapa 6: Deploy no Azure Container Instances (ACI) ---
    Write-Host "`n[ETAPA 6/7] Fazendo deploy no Container Instances..." -ForegroundColor Yellow
    $acrPassword = (az acr credential show --name $acrName --query "passwords[0].value" --output tsv)
    $dbConnectionString = "Host=$($postgresServerName).postgres.database.azure.com;Database=motodb;Username=$($postgresAdminUser);Password=$($postgresAdminPassword);SslMode=Require"

    az container create `
        --resource-group $resourceGroupName `
        --name motthru-api-container `
        --image $imageTag `
        --registry-login-server "$($acrName).azurecr.io" `
        --registry-username $acrName `
        --registry-password $acrPassword `
        --dns-name-label $dnsNameLabel `
        --ports 8080 `
        --os-type Linux `
        --environment-variables "ConnectionStrings__Postgres=$dbConnectionString" `
        --cpu 1 `
        --memory 1.0 `
        --output none
    Write-Host "--> Deploy do container iniciado. Aguardando provisionamento..." -ForegroundColor Green
    
    # --- Etapa 7: Verificação e Debug ---
    Write-Host "`n[ETAPA 7/7] Verificando o deploy e buscando logs..." -ForegroundColor Yellow
    Start-Sleep -Seconds 90 # Espera 90 segundos para o container tentar iniciar

    $containerState = (az container show --resource-group $resourceGroupName --name motthru-api-container --query "instanceView.state" --output tsv)
    Write-Host "--> Status atual do container: $containerState" -ForegroundColor Magenta
    
    $apiUrl = (az container show --resource-group $resourceGroupName --name motthru-api-container --query "ipAddress.fqdn" --output tsv)
    Write-Host "--> A API DEVE estar disponível em: http://$($apiUrl):8080/swagger" -ForegroundColor Magenta

    Write-Host "`n--> Exibindo os logs do container (procure por erros de conexão com o banco):"
    az container logs --resource-group $resourceGroupName --name motthru-api-container
    
    Write-Host "`n======================================================" -ForegroundColor Cyan
    Write-Host " SCRIPT FINALIZADO " -ForegroundColor Cyan
    Write-Host "======================================================"

}
catch {
    Write-Host "`n!!! OCORREU UM ERRO !!!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
