
---

# Tech Challenge – Backend AWS + EKS

## Arquitetura

A solução é composta por múltiplos componentes integrados dentro da AWS:

### 🔹 Autenticação e Cadastro

* **AWS Cognito**

  * Autenticação de usuários via CPF (username) e e-mail (alias único).
  * Geração e validação de tokens JWT.
* **AWS Lambda**

  * `registerUser` → Registra o usuário no Cognito e insere no banco de dados.
  * `userAuth` → Autentica o usuário via CPF e retorna token JWT.

### 🔹 API Gateway

* Exposição central dos endpoints:

  * `/user/register` e `/user/auth` → conectados às Lambdas.
  * `/user/api/...` → proxy reverso para os serviços no EKS.
* Proteção com **Custom JWT Authorizer** (Lambda Authorizer).
* Integrações via **HTTP_PROXY** para os serviços dentro do cluster.

### 🔹 Autorização (JWT Authorizer)

* Lambda `authorizer`

  * Executada automaticamente pelo **API Gateway** antes de qualquer endpoint protegido.
  * Valida o **token JWT** enviado no header `Authorization`.
  * Caso válido, o acesso é liberado e o contexto do usuário é injetado na requisição.
  * Caso inválido, retorna `401 Unauthorized`.
  * Integração configurada no Terraform via `aws_api_gateway_authorizer`.

### 🔹 Backend no EKS

* Aplicação rodando no cluster Kubernetes (EKS).
* Endpoints RESTful:

  * `/api/customer`
  * `/api/product`
  * `/api/order`
  * `/api/payment`
  * `/api/health`
* Comunicação via API Gateway com autenticação JWT.

### 🔹 Banco de Dados

* **Amazon RDS (PostgreSQL)** → Armazena dados de clientes e entidades de negócio (orders, products, etc).

---

## 🗂 Estrutura do Projeto

```bash
.
├── terraform/
│   ├── main.tf
│   ├── apigateway.tf
│   ├── cognito.tf
│   ├── lambdas.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── eks.tf
├── lambdas/
│   ├── registerUser/
│   │   └── index.js
│   ├── userAuth/
│   │   └── index.js
│   └── jwtAuthorizer/
│       └── index.js
└── README.md
```

---

## Deploy da Infraestrutura

### Pré-requisitos

* [Terraform](https://developer.hashicorp.com/terraform/downloads)
* AWS CLI configurado (`aws configure`)
* Bucket S3 para armazenamento de estado remoto (opcional)

### Passos

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

Isso criará:

* Cognito User Pool + User Pool Client
* Lambda Functions (`registerUser`, `userAuth`, `jwtAuthorizer`)
* API Gateway com todos os endpoints configurados
* Integrações HTTP Proxy com o EKS
* RDS PostgreSQL para persistência de dados

---

## Endpoints Principais

### `/user/register` → Registro de usuário

Fluxo:

1. Valida CPF e e-mail.
2. Verifica duplicidade:

   * CPF duplicado → `409 Conflict`
   * E-mail duplicado → `409 Conflict`
3. Cria o usuário no Cognito.
4. Marca o e-mail como verificado.
5. Insere no banco via RDS.

#### Exemplo de requisição:

```bash
curl --location 'https://<api-id>.execute-api.us-east-1.amazonaws.com/user/register' \
--header 'Content-Type: application/json' \
--data '{
  "cpf": "11076333911",
  "email": "test@example.com",
  "name": "Usuário Teste"
}'
```

#### Resposta:

```json
{
  "message": "Usuário registrado com sucesso!",
  "cpf": "11076333911",
  "db_customer_id": "db48c9e8-c2ba-41d6-9643-ec04cba6c401"
}
```

---

### `/user/auth` → Autenticação via CPF

Fluxo:

1. Busca usuário no Cognito via CPF.
2. Gera token JWT com payload contendo `cpf`, `email`, `name`.
3. Retorna o token ao cliente.

#### Exemplo:

```bash
curl --location 'https://<api-id>.execute-api.us-east-1.amazonaws.com/user/auth' \
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

## Endpoints Proxy (EKS)

Todos os endpoints abaixo são acessados via API Gateway com prefixo `/user/api/...`.

| Método   | Endpoint                                | Autenticação | Descrição                       |
| -------- | --------------------------------------- | ------------ | ------------------------------- |
| `GET`    | `/user/api/health`                      | ❌ Pública    | Checagem de saúde da aplicação  |
| `GET`    | `/user/api/customer`                    | ✅ JWT        | Lista clientes                  |
| `POST`   | `/user/api/customer`                    | ✅ JWT        | Cria cliente                    |
| `GET`    | `/user/api/customer/{id}`               | ✅ JWT        | Busca cliente por ID            |
| `GET`    | `/user/api/customer/cpf/{cpf}`          | ✅ JWT        | Busca cliente por CPF           |
| `PUT`    | `/user/api/customer/{id}`               | ✅ JWT        | Atualiza cliente                |
| `DELETE` | `/user/api/customer/{id}`               | ✅ JWT        | Deleta cliente                  |
| `GET`    | `/user/api/product`                     | ❌ Pública    | Lista produtos                  |
| `POST`   | `/user/api/product`                     | ✅ JWT        | Cria produto                    |
| `PUT`    | `/user/api/product`                     | ✅ JWT        | Atualiza produto                |
| `GET`    | `/user/api/product/{id}`                | ❌ Pública    | Detalhes do produto             |
| `DELETE` | `/user/api/product/{id}`                | ✅ JWT        | Exclui produto                  |
| `GET`    | `/user/api/product/category/{category}` | ❌ Pública    | Lista por categoria             |
| `GET`    | `/user/api/order`                       | ✅ JWT        | Lista pedidos                   |
| `POST`   | `/user/api/order`                       | ✅ JWT        | Cria pedido                     |
| `GET`    | `/user/api/order/{id}`                  | ✅ JWT        | Detalhes de pedido              |
| `PUT`    | `/user/api/order/{id}`                  | ✅ JWT        | Atualiza pedido                 |
| `DELETE` | `/user/api/order/{id}`                  | ✅ JWT        | Deleta pedido                   |
| `POST`   | `/user/api/payment`                     | ✅ JWT        | Cria pagamento                  |
| `GET`    | `/user/api/payment/{id}`                | ✅ JWT        | Detalhes de pagamento           |
| `POST`   | `/user/api/payment/webhook`             | ❌ Pública    | Webhook de retorno do pagamento |

---

## Banco de Dados (RDS)

Tabela base: `customer`

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

Configurações via variáveis de ambiente (`DB_*`).

---

## Variáveis de Ambiente (Lambda)

| Variável                                                  | Descrição                   |
| --------------------------------------------------------- | --------------------------- |
| `USER_POOL_ID`                                            | ID do Cognito User Pool     |
| `JWT_SECRET`                                              | Segredo JWT                 |
| `JWT_ISSUER`                                              | Nome do emissor do token    |
| `JWT_TTL_MIN`                                             | Tempo de expiração do token |
| `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` | Configurações do RDS        |

---

## Observações Importantes

* O CPF é o identificador principal (`Username`) no Cognito.
* O e-mail é um **alias único** (`alias_attributes = ["email"]`).
* Exceções de duplicidade:

  * `UsernameExistsException` → CPF duplicado.
  * `AliasExistsException` → e-mail duplicado.
* Todos os endpoints do `/api/*` são proxys diretos para o backend EKS via HTTP Proxy.
* O JWT Authorizer valida o token antes de permitir o acesso aos recursos protegidos.

---

## 👩‍💻 Desenvolvedores

| [<img src="https://avatars.githubusercontent.com/u/79323910?v=4" width=115><br><sub>Bianca Vediner</sub>](https://github.com/BiaVediner) | [<img src="https://avatars.githubusercontent.com/u/79324306?v=4" width=115><br><sub>Wesley Paternezi</sub>](https://github.com/WesleyPaternezi) | [<img src="https://avatars.githubusercontent.com/u/61800458?v=4" width=115><br><sub>Guilherme Paternezi</sub>](https://github.com/guilherme-paternezi) |
| :--------------------------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------------------------------------------------------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------: |

---
