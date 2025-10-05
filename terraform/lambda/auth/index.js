const {
  CognitoIdentityProviderClient,
  AdminGetUserCommand,
} = require("@aws-sdk/client-cognito-identity-provider");
const jwt = require("jsonwebtoken");

const region = process.env.AWS_REGION || "us-east-1";
const cognito = new CognitoIdentityProviderClient({ region });

const USER_POOL_ID = process.env.USER_POOL_ID;
const JWT_SECRET = process.env.JWT_SECRET;
const JWT_ISSUER = process.env.JWT_ISSUER || "ordermanagement-auth";
const JWT_TTL_MIN = parseInt(process.env.JWT_TTL_MIN || "15", 10);

function sanitizeCpf(input) {
  if (!input) throw new Error("CPF ausente.");
  const digits = String(input).replace(/\D/g, "");
  if (digits.length !== 11) {
    throw new Error(
      `CPF inválido: deve conter exatamente 11 dígitos (recebido ${digits.length}).`
    );
  }
  return digits;
}

exports.handler = async (event) => {
  try {
    const body = JSON.parse(event.body || "{}");
    const cpf = sanitizeCpf(body.cpf);

    if (!cpf) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: "CPF inválido ou ausente." }),
      };
    }

    console.log("Buscando usuário no Cognito com Username (CPF):", cpf);

    // Busca direta no Cognito
    const cmd = new AdminGetUserCommand({
      UserPoolId: USER_POOL_ID,
      Username: cpf,
    });

    const resp = await cognito.send(cmd);

    if (!resp || !resp.Username) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: `Usuário não encontrado com CPF ${cpf}` }),
      };
    }

    const attrs = Object.fromEntries(resp.UserAttributes.map(a => [a.Name, a.Value]));

    const payload = {
      sub: resp.Username,
      cpf,
      email: attrs.email || null,
      name: attrs.name || null,
      iss: JWT_ISSUER,
    };

    const token = jwt.sign(payload, JWT_SECRET, { expiresIn: `${JWT_TTL_MIN}m` });

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Autenticado com sucesso",
        token,
      }),
    };

  } catch (err) {
    console.error("Erro no auth:", err);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: "Erro interno ao autenticar.",
        detail: err.message,
      }),
    };
  }
};
