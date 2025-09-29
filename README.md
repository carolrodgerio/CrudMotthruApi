# CRUD Motthru API - Sprint 3 (Challenge FIAP)

Este projeto consiste em uma API REST para gerenciamento de motos, desenvolvida em .NET 8 e implantada na nuvem Azure utilizando uma arquitetura de contêineres e serviços gerenciados (PaaS).

## 1. Descrição da Solução

Esta API serve como um backend para um sistema de gerenciamento dos pátios da Mottu, empresa de aluguel de motos. Ela permite a realização de operações de CRUD (Criar, Ler, Atualizar e Deletar) para registros de motos, centralizando informações essenciais como placa, chassi e localização (pátio). A aplicação é construída com uma abordagem minimalista e moderna usando .NET 8.

## 2. Benefícios para o Negócio

* **Centralização da Informação:** Consolida todos os dados dos veículos em um único local, acessível via API.
* **Otimização de Processos:** Automatiza o registro e a consulta de informações, reduzindo o tempo gasto em operações manuais e a probabilidade de erros.
* **Escalabilidade e Disponibilidade:** A arquitetura em nuvem permite que a solução cresça conforme a demanda e garante alta disponibilidade, sem a necessidade de gerenciar servidores físicos.
* **Segurança:** Utiliza serviços gerenciados do Azure, que incluem robustas políticas de segurança e gerenciamento de acesso.

## 3. Arquitetura da Solução

A arquitetura implantada no Azure consiste nos seguintes componentes:

* **Azure Database for PostgreSQL:** Um serviço de banco de dados como serviço (PaaS) que armazena os dados da aplicação. Ele é responsável pela persistência dos registros de motos.
* **Azure Container Registry (ACR):** Um registro Docker privado e gerenciado no Azure. Ele armazena de forma segura a imagem Docker da nossa aplicação após o processo de build.
* **Azure Container Instances (ACI):** Um serviço que executa contêineres Docker sob demanda sem a necessidade de gerenciar máquinas virtuais. Ele é responsável por executar nossa API, tornando-a acessível pela internet.

O fluxo de implantação é automatizado via script, seguindo as melhores práticas de DevOps: `Código Local -> Build da Imagem Docker -> Push para o ACR -> Deploy no ACI`.

---

## 4. Guia de Implantação Automatizada

Este projeto utiliza um script PowerShell único para provisionar toda a infraestrutura e realizar o deploy da aplicação no Azure.

### Pré-requisitos

* [Docker Desktop](https://www.docker.com/products/docker-desktop/)
* [Azure CLI](https://docs.microsoft.com/pt-br/cli/azure/install-azure-cli) (logado em sua conta com `az login`)

### Passo a Passo para o Deploy

1.  **Clone o Repositório**
    ```bash
    git clone https://github.com/carolrodgerio/CrudMotthruApi
    cd CrudMotthruAPI
    ```

2.  **Configure o Script de Deploy**
    * Abra o arquivo `deploy.ps1` na raiz do projeto.
    * Na **Etapa 0**, edite as variáveis (`$resourceGroupName`, `$acrName`, etc.) com os nomes que você deseja para os seus recursos no Azure.

3.  **Execute o Script**
    * Abra um terminal PowerShell na raiz do projeto.
    * Execute o script com o comando:
    ```powershell
    .\deploy.ps1
    ```

O script cuidará de todo o processo: login, criação de recursos, build da imagem, push para o registro e deploy do contêiner. Ao final, ele exibirá a URL pública da sua API.

---

## 5. Testando a API

Após a execução bem-sucedida do script, a API estará disponível publicamente. Use as `curl` abaixo ou uma ferramenta como Postman/Insomnia para testar os endpoints.

**Substitua `<URL_DA_SUA_API>` pela URL fornecida no final do script de deploy (ex: `http://apisprint3devops.brazilsouth.azurecontainer.io:8080`).**

### Criar uma nova moto (POST)

```bash
curl -X POST "<URL_DA_SUA_API>/motos" \
-H "Content-Type: application/json" \
-d '{ "placa": "BRA2E19", "chassi": "9C8B7A6S5D4F3G2H1", "numMotor": "MOTOR123", "idModelo": 1, "idPatio": 1 }'
```

### Consultar todas as motos (GET)

```bash
curl -X GET "<URL_DA_SUA_API>/motos"
```

### Consultar uma moto por ID (GET)

```bash
# Exemplo para consultar a moto com id = 1
curl -X GET "<URL_DA_SUA_API>/motos/1"
```

### Atualizar uma moto (PUT)

```bash
# Exemplo para atualizar a moto com id = 1
curl -X PUT "<URL_DA_SUA_API>/motos/1" \
-H "Content-Type: application/json" \
-d '{ "placa": "MER4C05", "chassi": "9C8B7A6S5D4F3G2H1", "numMotor": "MOTOR456", "idModelo": 2, "idPatio": 5 }'
```

### Deletar uma moto (DELETE)

```bash
# Exemplo para deletar a moto com id = 1
curl -X DELETE "<URL_DA_SUA_API>/motos/1"
```

---

## 6. Conectando-se ao Banco de Dados na Nuvem

Após o deploy, você pode querer verificar os dados diretamente no banco de dados PostgreSQL para depuração ou para a demonstração. Abaixo estão as instruções para se conectar usando diferentes ferramentas.

### Pré-requisito Essencial: Liberar seu IP no Firewall

Por padrão, o banco de dados no Azure bloqueia conexões de IPs desconhecidos. Para se conectar da sua máquina local, você precisa adicionar uma regra de firewall.
Execute o comando abaixo no PowerShell (substituindo <SEU_IP_PUBLICO_AQUI> pelo seu IP):

```powershell
# Use as mesmas variáveis do seu script de deploy
$resourceGroupName="<NOME DO RG>"
$postgresServerName="<NOME DO SERVER DB>"

az postgres flexible-server firewall-rule create `
    --resource-group $resourceGroupName `
    --name $postgresServerName `
    --rule-name "AllowMyLocalIP" `
    --start-ip-address "<SEU_IP_PUBLICO_AQUI>" `
    --end-ip-address "<SEU_IP_PUBLICO_AQUI>"
```

**Método 1: DBeaver**
- Crie uma nova conexão e selecione PostgreSQL.
- Preencha os parâmetros "Host", "Database", "Username" e "Password":
- Na aba SSL, marque a opção "Use SSL" e configure o "SSL Mode" para require.
- Teste a conexão e salve.

**Método 2: VS Code**
- Instale a extensão PostgreSQL da Microsoft.
- Clique no ícone da extensão na barra lateral e em "+" para adicionar uma nova conexão.
- Preencha os mesmos parâmetros listados para o DBeaver.
- Quando solicitado, selecione a opção de SSL Require.

**Método 3: Linha de Comando (psql)**
- Certifique-se de ter o cliente psql do PostgreSQL instalado em sua máquina.
- Execute o seguinte comando no PowerShell. Ele utilizará a CLI do Azure para facilitar a conexão:

```powershell
az postgres flexible-server connect `
    --name "<NOME DO SERVER DB>" `
    --admin-user "<NOME DO USUÁRIO>" `
    --database-name "motodb"
```

- Digite a senha quando solicitado.
- Após conectar, você pode executar queries SQL diretamente, como SELECT * FROM motos;. Para sair, digite \q.

---

## Materiais Complementares

- Vídeo no YouTube: 
- Apresentação em PDF:

_Feito com 🩷 por Carolina, Enrico e Lucas_
