const jwt = require("jsonwebtoken");

exports.handler = async (event) => {
  console.log("Event recebido:", JSON.stringify(event));

  try {
    const token = event.headers?.Authorization?.split(" ")[1];
    if (!token) throw new Error("Missing token");

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const methodArnParts = event.methodArn.split("/");

    const apiGatewayArn = methodArnParts[0];
    const stage = methodArnParts[1];

    const wildcardArn = `${apiGatewayArn}/${stage}/*/*`;

    console.log("Liberando todas as rotas no stage:", wildcardArn);

    return {
      principalId: decoded.sub || decoded.cpf || "anonymous",
      policyDocument: {
        Version: "2012-10-17",
        Statement: [
          {
            Action: "execute-api:Invoke",
            Effect: "Allow",
            Resource: wildcardArn,
          },
        ],
      },
      context: {
        userId: decoded.sub,
        cpf: decoded.cpf,
      },
    };
  } catch (err) {
    console.error("Token inválido:", err.message);
    return {
      principalId: "unauthorized",
      policyDocument: {
        Version: "2012-10-17",
        Statement: [
          {
            Action: "execute-api:Invoke",
            Effect: "Deny",
            Resource: "*",
          },
        ],
      },
    };
  }
};
