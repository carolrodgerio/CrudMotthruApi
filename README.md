# CRUD Motthru API - Sprint 3 (Challenge)

Este projeto consiste em uma API REST para o projeto MOTTHRU, focada no gerenciamento de motos. A aplicação foi desenvolvida em .NET 8, conteinerizada com Docker e implantada na nuvem do Azure utilizando o modelo PaaS (Platform as a Service).

## 📋 Integrantes

* [Carolina Estevam Rodgerio](https://github.com/carolrodgerio)
* [Lucas Thalles dos Santos](https://github.com/lucasthalless)
* [Enrico Andrade D'Amico](https://github.com/enrico-ad)

---

## 1. Descrição da Solução

A solução é uma API RESTful desenvolvida em **.NET 8** utilizando o padrão **Minimal API** para simplicidade e performance. Ela expõe endpoints para realizar operações de **CRUD (Create, Read, Update, Delete)** em uma entidade de "Moto".

A aplicação é projetada para ser executada em contêineres **Docker**, garantindo portabilidade e consistência entre ambientes. O deploy é feito no **Azure App Service**, um serviço de plataforma gerenciado, e a persistência de dados é realizada por um **Banco de Dados do Azure para PostgreSQL**, também como um serviço gerenciado (PaaS). A arquitetura é totalmente baseada em nuvem, escalável e robusta.

---

## 2. Benefícios para o Negócio

Esta API é o componente fundamental para o sistema MOTTHRU, servindo como a principal porta de entrada para o registro e gerenciamento de motos. Os principais benefícios incluem:

* **Centralização da Informação:** Cria uma fonte única e confiável para os dados das motos, acessível por outros sistemas e aplicações.
* **Controle de Ativos:** Permite o rastreamento digital do inventário de motos, o que leva a um melhor controle, redução de perdas e otimização do gerenciamento de pátios.
* **Base para Escalabilidade:** Por ser uma API em nuvem, ela serve como base para futuras expansões do sistema, como aplicativos móveis para vistorias, dashboards de BI e integrações com sistemas de RFID.
* **Automação de Processos:** Automatiza o processo de cadastro e atualização de informações, reduzindo a necessidade de controles manuais e a probabilidade de erros.

---

## 🛠️ Tecnologias Utilizadas

* **Backend:** .NET 8, ASP.NET Core (Minimal API)
* **Banco de Dados:** PostgreSQL
* **ORM:** Entity Framework Core 8
* **Conteinerização:** Docker
* **Plataforma Cloud:** Microsoft Azure
    * **Hospedagem da API:** Azure App Service for Containers
    * **Hospedagem do Banco:** Azure Database for PostgreSQL (Flexible Server)
    * **Registro de Imagem:** Azure Container Registry (ACR)
* **Infraestrutura como Código:** Azure CLI

---

## 🚀 Instruções de Deploy e Teste via Azure CLI

Este guia descreve o processo completo para implantar a solução do zero, utilizando o terminal PowerShell.

### Pré-requisitos
* [Azure CLI](https://aka.ms/installazurecliwindows) instalado e autenticado (`az login`).
* [Docker Desktop](https://www.docker.com/products/docker-desktop/) em execução.

### Passo a Passo da Implantação

Execute os comandos abaixo em sequência no seu terminal PowerShell.

#### 1. Preparação Local
```powershell
# Gere os arquivos de migração do banco de dados
dotnet ef migrations add InitialCreate --project CrudMotthruApi
```

#### 2. Criação da Infraestrutura Base no Azure
```powershell
# Crie o grupo de recursos
az group create --name CrudMotthru-RG --location "Brazil South"

# Crie o Azure Container Registry (ACR)
az acr create --resource-group CrudMotthru-RG --name crudmotthruacr2025 --sku Basic

# Crie o servidor PostgreSQL PaaS
az postgres flexible-server create --resource-group CrudMotthru-RG --name crudmotthru-pgserver-2025 --admin-user motthruadmin --admin-password "F!ap1234#" --sku-name Standard_B1ms --tier Burstable --public-access 0.0.0.0-255.255.255.255

# Crie o banco de dados 'motthru_db' dentro do servidor
az postgres flexible-server db create --resource-group CrudMotthru-RG --server-name crudmotthru-pgserver-2025 --database-name motthru_db
```

#### 3. Criação da Infraestrutura Base no Azure
```powershell
# Faça login no ACR
az acr login --name crudmotthruacr2025

# Construa a imagem Docker localmente a partir da raiz do projeto
docker build -t crudmotthru-api-image .

# Faça a tag da imagem para o ACR
docker tag crudmotthru-api-image crudmotthruacr2025.azurecr.io/crudmotthru-api:v1

# Envie a imagem para o ACR
docker push crudmotthruacr2025.azurecr.io/crudmotthru-api:v1
```

#### 4. Criação e Configuração do App Service
```powershell
# Crie o Plano do App Service
az appservice plan create --name crudmotthru-app-plan --resource-group CrudMotthru-RG --sku B1 --is-linux

# Crie o Web App, já apontando para a imagem no ACR
az webapp create --resource-group CrudMotthru-RG --plan crudmotthru-app-plan --name crudmotthru-webapp-2025 --deployment-container-image-name crudmotthruacr2025.azurecr.io/crudmotthru-api:v1

# Obtenha as senhas e a string de conexão para configurar o Web App
$ACR_PASSWORD = (az acr credential show -n crudmotthruacr2025 --query "passwords[0].value" -o tsv)
$CONN_STRING = (az postgres flexible-server show-connection-string -s crudmotthru-pgserver-2025 -u motthruadmin -d motthru_db -p "F!ap1234#" --query "connectionStrings.ado_net" -o tsv)

# Configure o acesso do Web App ao ACR
az webapp config container set --name crudmotthru-webapp-2025 --resource-group CrudMotthru-RG --docker-registry-server-url https://crudmotthruacr2025.azurecr.io --docker-registry-server-user crudmotthruacr2025 --docker-registry-server-password $ACR_PASSWORD

# Configure a string de conexão do banco e a porta interna do contêiner
az webapp config appsettings set --resource-group CrudMotthru-RG --name crudmotthru-webapp-2025 --settings "ConnectionStrings__Postgres=$CONN_STRING" "WEBSITES_PORT=8080"
```

### Validação

* Aguarde de 2 a 5 minutos para o App Service iniciar o contêiner.
* Acesse a URL da aplicação no navegador, adicionando /swagger no final: http://crudmotthru-webapp-2025.azurewebsites.net/swagger
* Utilize a interface do Swagger para testar todos os endpoints de CRUD.

---

## 🚀 Exemplos de JSON para testes

### 1. Criar uma moto (POST /motos)
```json
{
  "placa": "RST5F67",
  "chassi": "9C6ABC123XYZ78901",
  "numMotor": "MOTOR9876",
  "idModelo": 10,
  "idPatio": 20
}
```

### 2. Atualizar uma moto (PUT /motos/{id})
```json
{
  "id": 1,
  "placa": "RST5F67",
  "chassi": "9C6ABC123XYZ78901",
  "numMotor": "MOTOR_ATUALIZADO",
  "idModelo": 11,
  "idPatio": 22
}
```

### 3. Listar motos (GET /motos)
```json
[
  {
    "id": 1,
    "placa": "RST5F67",
    "chassi": "9C6ABC123XYZ78901",
    "numMotor": "MOTOR9876",
    "idModelo": 10,
    "idPatio": 20
  },
  {
    "id": 2,
    "placa": "QWE8R90",
    "chassi": "9C6DEF456ABC12345",
    "numMotor": "MOTOR1234",
    "idModelo": 12,
    "idPatio": 20
  }
]
```

### 4. Deletar uma moto (DELETE /motos/{id})
```
Exclui a moto correspondente ao ID informado. Não é necessário enviar um corpo (body) na requisição.
```
