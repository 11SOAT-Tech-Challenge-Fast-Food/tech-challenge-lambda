const {
  CognitoIdentityProviderClient,
  AdminInitiateAuthCommand,
} = require("@aws-sdk/client-cognito-identity-provider");
const jwt = require("jsonwebtoken");

// ==== Configurações ====
const region = process.env.AWS_REGION || "us-east-1";
const USER_POOL_ID = process.env.USER_POOL_ID;
const CLIENT_ID = process.env.USER_POOL_CLIENT_ID;
const JWT_SECRET = process.env.JWT_SECRET;
const JWT_ISSUER = process.env.JWT_ISSUER || "ordermanagement-auth";
const JWT_TTL_MIN = parseInt(process.env.JWT_TTL_MIN || "15", 10);
const DEFAULT_PASSWORD = process.env.DEFAULT_PASSWORD || "SENHABOa12345#";

const cognito = new CognitoIdentityProviderClient({ region });

// ==== Utilitário ====
function sanitizeCpf(input) {
  if (!input) throw new Error("CPF ausente.");
  const digits = String(input).replace(/\D/g, "");
  if (digits.length !== 11) {
    throw new Error(`CPF inválido: deve conter exatamente 11 dígitos (recebido ${digits.length}).`);
  }
  return digits;
}

// ==== Handler ====
exports.handler = async (event) => {
  console.log("==== INÍCIO AUTH ====");
  console.log("Evento recebido:", JSON.stringify(event, null, 2));

  try {
    const body = JSON.parse(event.body || "{}");
    const cpf = body.cpf ? sanitizeCpf(body.cpf) : null;

    if (!cpf) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: "CPF é obrigatório para autenticação." }),
      };
    }

    if (!USER_POOL_ID || !CLIENT_ID) {
      console.error("Variáveis de ambiente ausentes:", { USER_POOL_ID, CLIENT_ID });
      return {
        statusCode: 500,
        body: JSON.stringify({ message: "Configuração inválida: USER_POOL_ID ou CLIENT_ID ausente." }),
      };
    }

    console.log(`Iniciando autenticação Cognito para CPF: ${cpf}`);

    const authCmd = new AdminInitiateAuthCommand({
      AuthFlow: "ADMIN_USER_PASSWORD_AUTH",
      UserPoolId: USER_POOL_ID,
      ClientId: CLIENT_ID,
      AuthParameters: {
        USERNAME: cpf,
        PASSWORD: DEFAULT_PASSWORD,
      },
    });

    const authResp = await cognito.send(authCmd);

    if (!authResp.AuthenticationResult?.AccessToken) {
      throw new Error("Falha na autenticação do Cognito (sem token retornado).");
    }

    // === Cria o JWT interno ===
    const payload = {
      sub: cpf,
      cpf,
      iss: JWT_ISSUER,
    };

    const signedJwt = jwt.sign(payload, JWT_SECRET, { expiresIn: `${JWT_TTL_MIN}m` });

    console.log("Autenticação bem-sucedida. JWT gerado para:", cpf);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Autenticação bem-sucedida.",
        cognito_access_token: authResp.AuthenticationResult.AccessToken,
        jwt: signedJwt,
      }),
    };
  } catch (err) {
    console.error("Erro na autenticação:", err);

    let message = "Falha na autenticação.";
    if (err.name === "NotAuthorizedException") message = "Usuário ou senha incorretos.";
    else if (err.name === "UserNotFoundException") message = "Usuário não encontrado.";
    else if (err.name === "UserNotConfirmedException") message = "Usuário ainda não confirmado.";

    return {
      statusCode: 401,
      body: JSON.stringify({
        message,
        detail: err.message,
      }),
    };
  } finally {
    console.log("==== FIM AUTH ====");
  }
};
