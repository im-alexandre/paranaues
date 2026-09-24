'use strict';

// Local HTTP proxy for winget when the upstream proxy requires credentials.
// Credentials are read from HTTPS_PROXY and never printed or passed to winget.
const http = require('node:http');
const net = require('node:net');

const upstream = new URL(process.env.HTTPS_PROXY || process.env.HTTP_PROXY);
const auth = 'Basic ' + Buffer.from(
  `${decodeURIComponent(upstream.username)}:${decodeURIComponent(upstream.password)}`
).toString('base64');
const host = upstream.hostname;
const port = Number(upstream.port || 80);
const listenPort = Number(process.env.WINGET_PROXY_PORT || 0);

if (!Number.isInteger(listenPort) || listenPort < 0 || listenPort > 65535) {
  throw new Error('WINGET_PROXY_PORT must be a valid TCP port.');
}

const server = http.createServer((request, response) => {
  const headers = { ...request.headers, 'proxy-authorization': auth };
  delete headers['proxy-connection'];
  const upstreamRequest = http.request({
    host,
    port,
    method: request.method,
    path: request.url,
    headers,
  }, (upstreamResponse) => {
    response.writeHead(upstreamResponse.statusCode, upstreamResponse.headers);
    upstreamResponse.pipe(response);
  });
  upstreamRequest.on('error', () => {
    if (!response.headersSent) response.writeHead(502);
    response.end();
  });
  request.pipe(upstreamRequest);
});

server.on('connect', (request, client, head) => {
  const upstreamRequest = http.request({
    host,
    port,
    method: 'CONNECT',
    path: request.url,
    headers: {
      host: request.url,
      'proxy-authorization': auth,
    },
  });

  upstreamRequest.on('connect', (upstreamResponse, tunnel, upstreamHead) => {
    if (upstreamResponse.statusCode !== 200) {
      client.end(`HTTP/1.1 502 Bad Gateway\r\n\r\n`);
      tunnel.destroy();
      return;
    }
    client.write('HTTP/1.1 200 Connection Established\r\n\r\n');
    if (head.length) tunnel.write(head);
    if (upstreamHead.length) client.write(upstreamHead);
    client.pipe(tunnel);
    tunnel.pipe(client);
    client.on('error', () => tunnel.destroy());
    tunnel.on('error', () => client.destroy());
  });
  upstreamRequest.on('error', () => client.destroy());
  client.on('error', () => upstreamRequest.destroy());
  upstreamRequest.end();
});

server.listen(listenPort, '127.0.0.1', () => {
  process.stdout.write(String(server.address().port) + '\n');
});
