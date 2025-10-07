const jwt = require("jsonwebtoken");

exports.handler = async (event) => {
  try {
    const token = event.headers?.Authorization?.split(" ")[1]; // se vier como REQUEST
    if (!token) throw new Error("Missing token");

    const decoded = jwt.verify(token, process.env.JWT_SECRET); // mesmo segredo usado em /auth

    return {
      principalId: decoded.sub || decoded.cpf || "anonymous",
      policyDocument: {
        Version: "2012-10-17",
        Statement: [
          {
            Action: "execute-api:Invoke",
            Effect: "Allow",
            Resource: event.methodArn,
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
            Resource: event.methodArn,
          },
        ],
      },
    };
  }
};
