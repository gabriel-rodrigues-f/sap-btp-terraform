'use strict';

// App de demonstração SEM dependências externas (só módulos nativos do Node),
// para que o foco da POC fique em Terraform + Ansible e não em npm.
//
//   GET /            -> metadados do app (space, serviços ligados)
//   GET /health      -> health check usado pelo Cloud Foundry e pelo smoke test
//   GET /destination -> lê, via Destination service, a destination configurada
//                       em DESTINATION_NAME (criada pelo Terraform no stack 10)

const http = require('node:http');

const PORT = Number(process.env.PORT) || 8080;
const DESTINATION_NAME = process.env.DESTINATION_NAME || 'northwind';

const log = (level, msg, extra = {}) =>
  console.log(JSON.stringify({ level, msg, time: new Date().toISOString(), ...extra }));

const vcapServices = () => JSON.parse(process.env.VCAP_SERVICES || '{}');
const vcapApplication = () => JSON.parse(process.env.VCAP_APPLICATION || '{}');

function boundServiceCredentials(label) {
  const [instance] = vcapServices()[label] || [];
  if (!instance) {
    const err = new Error(`Nenhuma instância do serviço "${label}" ligada ao app`);
    err.status = 503;
    throw err;
  }
  return instance.credentials;
}

async function getDestination(name) {
  // Credenciais do binding: clientid/clientsecret + url (XSUAA) + uri (API).
  const { clientid, clientsecret, url, uri } = boundServiceCredentials('destination');

  const tokenResponse = await fetch(`${url}/oauth/token`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${Buffer.from(`${clientid}:${clientsecret}`).toString('base64')}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({ grant_type: 'client_credentials', client_id: clientid }),
  });
  if (!tokenResponse.ok) throw new Error(`Falha ao obter token: HTTP ${tokenResponse.status}`);
  const { access_token: accessToken } = await tokenResponse.json();

  const destinationResponse = await fetch(
    `${uri}/destination-configuration/v1/destinations/${encodeURIComponent(name)}`,
    { headers: { Authorization: `Bearer ${accessToken}` } },
  );
  if (!destinationResponse.ok) {
    const err = new Error(`Destination "${name}" não encontrada: HTTP ${destinationResponse.status}`);
    err.status = destinationResponse.status === 404 ? 404 : 502;
    throw err;
  }
  const { destinationConfiguration: cfg } = await destinationResponse.json();

  // Devolvemos só campos não sensíveis. Nunca exponha tokens/senhas da destination.
  return {
    name: cfg.Name,
    type: cfg.Type,
    url: cfg.URL,
    proxyType: cfg.ProxyType,
    authentication: cfg.Authentication,
  };
}

const send = (res, status, body) => {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(body));
};

const routes = {
  '/health': async () => [200, { status: 'UP' }],
  '/': async () => {
    const app = vcapApplication();
    return [200, {
      app: app.application_name,
      space: app.space_name,
      org: app.organization_name,
      instance: Number(process.env.CF_INSTANCE_INDEX || 0),
      boundServices: Object.keys(vcapServices()),
      destinationName: DESTINATION_NAME,
    }];
  },
  '/destination': async () => [200, await getDestination(DESTINATION_NAME)],
};

const server = http.createServer(async (req, res) => {
  const { pathname } = new URL(req.url, 'http://localhost');
  const handler = req.method === 'GET' ? routes[pathname] : undefined;
  if (!handler) return send(res, 404, { error: 'not found' });

  try {
    const [status, body] = await handler();
    send(res, status, body);
  } catch (err) {
    log('error', err.message, { path: pathname });
    send(res, err.status || 500, { error: err.message });
  }
});

server.listen(PORT, () => log('info', `hello-btp ouvindo na porta ${PORT}`));

// Cloud Foundry envia SIGTERM antes de parar a instância (ex.: rolling deploy).
process.on('SIGTERM', () => server.close(() => process.exit(0)));
