const {
  CognitoIdentityProviderClient,
  ListUsersCommand,
  AdminCreateUserCommand,
  AdminUpdateUserAttributesCommand,
  AdminSetUserPasswordCommand,
} = require("@aws-sdk/client-cognito-identity-provider");
const { Client } = require("pg");
const { randomUUID } = require("crypto");

// ==== Configurações ====
const region = process.env.AWS_REGION || "us-east-1";
const USER_POOL_ID = process.env.USER_POOL_ID;
const DEFAULT_PASSWORD = process.env.DEFAULT_PASSWORD || "SENHABOa12345#";

const DB_CONFIG = {
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: { rejectUnauthorized: false },
};

const cognito = new CognitoIdentityProviderClient({ region });

// ==== Utilitários ====
function sanitizeCpf(input) {
  if (!input) throw new Error("CPF ausente.");
  const digits = String(input).replace(/\D/g, "");
  if (digits.length !== 11) {
    throw new Error(`CPF inválido: deve conter exatamente 11 dígitos (recebido ${digits.length}).`);
  }
  return digits;
}

// ==== Handler principal ====
exports.handler = async (event) => {
  console.log("==== INÍCIO REQUEST ====");
  console.log("Evento recebido:", JSON.stringify(event, null, 2));

  let dbClient;
  const responseLog = { steps: [] };

  try {
    const body = JSON.parse(event.body || "{}");
    const { name, email } = body;
    const cpf = body.cpf ? sanitizeCpf(body.cpf) : null;

    if (!cpf && !email) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: "Informe ao menos CPF ou e-mail." }),
      };
    }

    // === Verificação de duplicidade de e-mail ===
    if (email) {
      try {
        responseLog.steps.push("Verificando duplicidade de e-mail");
        const listCmd = new ListUsersCommand({
          UserPoolId: USER_POOL_ID,
          Filter: `email = "${email}"`,
          Limit: 1,
        });

        const listResp = await cognito.send(listCmd);

        if (listResp.Users && listResp.Users.length > 0) {
          console.warn("E-mail duplicado detectado:", email);
          return {
            statusCode: 409,
            body: JSON.stringify({
              message: "E-mail já registrado no sistema.",
              email,
            }),
          };
        }
      } catch (err) {
        console.error("Erro ao verificar duplicidade de e-mail:", err);
        throw new Error("Falha ao consultar duplicidade no Cognito.");
      }
    }

    // === Criação do usuário no Cognito ===
    try {
      responseLog.steps.push("Criando usuário no Cognito");

      const createCmd = new AdminCreateUserCommand({
        UserPoolId: USER_POOL_ID,
        Username: cpf,
        UserAttributes: [
          ...(email ? [{ Name: "email", Value: email }] : []),
          ...(name ? [{ Name: "name", Value: name }] : []),
        ],
        MessageAction: "SUPPRESS",
      });

      await cognito.send(createCmd);
      console.log("Usuário criado com sucesso no Cognito:", cpf);

      // === Define senha padrão permanente ===
      const setPassCmd = new AdminSetUserPasswordCommand({
        UserPoolId: USER_POOL_ID,
        Username: cpf,
        Password: DEFAULT_PASSWORD,
        Permanent: true,
      });

      await cognito.send(setPassCmd);
      console.log(`Senha padrão definida para o usuário ${cpf}`);

      // === Marca e-mail como verificado ===
      if (email) {
        responseLog.steps.push("Marcando e-mail como verificado");
        const updateCmd = new AdminUpdateUserAttributesCommand({
          UserPoolId: USER_POOL_ID,
          Username: cpf,
          UserAttributes: [{ Name: "email_verified", Value: "true" }],
        });
        await cognito.send(updateCmd);
        console.log("E-mail verificado com sucesso:", email);
      }
    } catch (err) {
      console.error("Erro Cognito:", err);
      if (err.name === "UsernameExistsException") {
        return {
          statusCode: 409,
          body: JSON.stringify({
            message: "CPF já registrado no sistema.",
            detail: err.message,
          }),
        };
      }
      throw err;
    }

    // === Conexão com o banco ===
    try {
      responseLog.steps.push("Conectando ao banco");
      dbClient = new Client(DB_CONFIG);
      await dbClient.connect();
      console.log("Conexão ao banco estabelecida:", DB_CONFIG.host);
    } catch (err) {
      console.error("Erro ao conectar ao banco:", err);
      throw new Error("Falha ao conectar ao banco de dados: " + err.message);
    }

    // === Inserção no RDS ===
    try {
      responseLog.steps.push("Inserindo cliente no banco");

      const id = randomUUID();
      const insertQuery = `
        INSERT INTO customer (id, name, email, cpf, created_at, updated_at)
        VALUES ($1, $2, $3, $4, NOW(), NOW())
        RETURNING id;
      `;

      console.log("Executando query SQL:", insertQuery);
      console.log("Parâmetros:", [id, name, email, cpf]);

      const result = await dbClient.query(insertQuery, [
        id,
        name || null,
        email || null,
        cpf || null,
      ]);

      const dbId = result.rows?.[0]?.id || null;

      console.log("Cliente inserido com sucesso, ID:", dbId);

      return {
        statusCode: 201,
        body: JSON.stringify({
          message: "Usuário registrado com sucesso!",
          cpf,
          db_customer_id: dbId,
          audit: responseLog.steps,
        }),
      };
    } catch (err) {
      console.error("Erro durante INSERT no banco:", err);
      throw new Error("Falha ao inserir no banco: " + err.message);
    }
  } catch (err) {
    console.error("Erro geral:", err);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: "Erro ao registrar usuário.",
        detail: err.message,
      }),
    };
  } finally {
    if (dbClient) {
      await dbClient.end();
      console.log("Conexão com o banco encerrada.");
    }
    console.log("==== FIM REQUEST ====");
  }
};
