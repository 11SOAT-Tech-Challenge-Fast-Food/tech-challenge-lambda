## Arquitetura

A solução é composta por:

- **AWS Cognito** → Autenticação de usuários via CPF (username) e e-mail como alias único.
- **AWS Lambda**
  - `registerUser`: Registra o usuário no Cognito e insere no banco de dados.
  - `userAuth`: Autentica o usuário via CPF e gera token JWT.
- **Amazon RDS (PostgreSQL)** → Armazena dados persistentes de clientes.
- **API Gateway** → Expõe endpoints públicos `/user/register` e `/user/auth`.

---
## Estrutura do Projeto
```

.
├── terraform/
│   ├── main.tf
│   ├── cognito.tf
│   ├── api_lambda.tf
│   ├── variables.tf
│   └── outputs.tf
├── lambdas/
│   ├── registerUser/
│   │   └── index.js
│   └── userAuth/
│       └── index.js
└── README.md

````

---

## Deploy da Infraestrutura

### Pré-requisitos

- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- Conta AWS configurada (`aws configure`)

### Passos

```bash
cd terraform
terraform init
terraform plan
terraform apply
````

Isso criará:
* Cognito User Pool
* Cognito User Pool Client
* API Gateway (com endpoints `/user/register` e `/user/auth`)
* Lambdas e permissões necessárias

---
## Sobre as Lambdas

### `/user/register`

Fluxo:

1. Valida CPF e/ou e-mail.
2. Verifica duplicidade:

   * CPF duplicado → `409 Conflict`
   * E-mail duplicado (via alias do Cognito) → `409 Conflict`
3. Cria o usuário no Cognito.
4. Marca o e-mail como verificado.
5. Insere o cliente no RDS.

#### Exemplo de requisição:

```bash
curl --location 'https://aws.execute-api.us-east-1.amazonaws.com/user/register' \
--header 'Content-Type: application/json' \
--data-raw '{
    "cpf": "11076333911",
    "email": "verd123@test.com",
    "name": "verds"
}'

```

#### Resposta:

```json
{
  "message": "Usuário registrado com sucesso!",
  "cpf": "11076333911",
  "db_customer_id": "db48c9e8-c2ba-41d6-9643-ec04cba6c401",
  "audit": [
    "Criando usuário no Cognito",
    "Marcando e-mail como verificado",
    "Conectando ao banco",
    "Inserindo cliente no banco"
  ]
}
```

---

### `/user/auth`

Fluxo:

1. Recebe o CPF.
2. Busca o usuário no Cognito.
3. Gera token JWT com payload:

   ```json
   {
     "sub": "11076333911",
     "cpf": "11076333911",
     "email": "user@test.com",
     "name": "Usuário Teste"
   }
   ```

#### Exemplo:

```bash
curl --location 'https://aws.execute-api.us-east-1.amazonaws.com/user/auth' \
--header 'Content-Type: application/json' \
--data '{
    "cpf": "11076333911"
}'
```

#### Resposta:

```json
{
  "message": "Autenticado com sucesso",
  "token": "eyJhbGciOiJIUzI1NiIsInR5..."
}
```

---

## Banco de Dados (RDS)

Tabela: `customer`

```sql
CREATE TABLE IF NOT EXISTS customer(
  id UUID PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  cpf VARCHAR(11),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

Conexão configurada nas variáveis de ambiente das Lambdas:

| Variável      | Descrição       |
| ------------- | --------------- |
| `DB_HOST`     | Endpoint do RDS |
| `DB_PORT`     | Porta (5432)    |
| `DB_NAME`     | Nome do banco   |
| `DB_USER`     | Usuário         |
| `DB_PASSWORD` | Senha           |

---

## Variáveis de Ambiente (Lambda)

| Variável       | Descrição                         |
| -------------- | --------------------------------- |
| `USER_POOL_ID` | ID do Cognito User Pool           |
| `JWT_SECRET`   | Segredo JWT                       |
| `JWT_ISSUER`   | Nome do emissor do token          |
| `JWT_TTL_MIN`  | Tempo de expiração do token       |
| `DB_*`         | Configurações do banco PostgreSQL |

---

## Observações

* O CPF é o identificador (`Username`) principal no Cognito.
* O e-mail é um alias **único** (`alias_attributes = ["email"]`).
* Em caso de duplicidade de CPF → `UsernameExistsException`.
* Em caso de duplicidade de e-mail → `AliasExistsException`.

## Desenvolvedores
| [<img loading="lazy" src="https://avatars.githubusercontent.com/u/79323910?v=4" width=115><br><sub>Bianca Vediner</sub>](https://github.com/BiaVediner) | [<img loading="lazy" src="https://avatars.githubusercontent.com/u/79324306?v=4" width=115><br><sub>Wesley Paternezi</sub>](https://github.com/WesleyPaternezi) | [<img loading="lazy" src="https://avatars.githubusercontent.com/u/61800458?v=4 " width=115><br><sub>Guilherme Paternezi</sub>](https://github.com/guilherme-paternezi) |
|:-----------------------------------------------------------------------------------------------------------------------------------------------------------:|:---------------------------------------------------------------------------------------------------------------------------------------------------------------:|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------:|