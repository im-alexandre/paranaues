"use strict";

// Local HTTP proxy for winget when the upstream proxy requires credentials.
// Credentials are read from HTTPS_PROXY and never printed or passed to winget.
const http = require("node:http");
const net = require("node:net");
const https = require("node:https");
const tls = require("node:tls");

const upstream = new URL(process.env.HTTPS_PROXY || process.env.HTTP_PROXY);
const auth =
  "Basic " +
  Buffer.from(
    `${decodeURIComponent(upstream.username)}:${decodeURIComponent(upstream.password)}`,
  ).toString("base64");
const host = upstream.hostname;
const port = Number(upstream.port || 80);
const listenPort = Number(process.env.WINGET_PROXY_PORT || 0);

if (!Number.isInteger(listenPort) || listenPort < 0 || listenPort > 65535) {
  throw new Error("WINGET_PROXY_PORT must be a valid TCP port.");
}

// The upstream proxy blocks forward-style "https://" requests (as sent by axios-based
// clients such as `claude rc`), so convert them into CONNECT tunnel + TLS.
function forwardHttps(request, response) {
  const target = new URL(request.url);
  const fail = () => {
    if (!response.headersSent) response.writeHead(502);
    response.end();
  };
  const connectRequest = http.request({
    host,
    port,
    method: "CONNECT",
    path: `${target.hostname}:${target.port || 443}`,
    headers: { host: `${target.hostname}:${target.port || 443}`, "proxy-authorization": auth },
  });
  connectRequest.on("connect", (upstreamResponse, tunnel) => {
    if (upstreamResponse.statusCode !== 200) {
      tunnel.destroy();
      return fail();
    }
    const secure = tls.connect({ socket: tunnel, servername: target.hostname });
    const headers = { ...request.headers, host: target.host };
    delete headers["proxy-authorization"];
    delete headers["proxy-connection"];
    const outbound = https.request(
      {
        method: request.method,
        path: target.pathname + target.search,
        headers,
        createConnection: () => secure,
      },
      (inbound) => {
        response.writeHead(inbound.statusCode, inbound.headers);
        inbound.pipe(response);
      },
    );
    outbound.on("error", fail);
    request.pipe(outbound);
  });
  connectRequest.on("error", fail);
  connectRequest.end();
}

const server = http.createServer((request, response) => {
  if (request.url.startsWith("https://")) return forwardHttps(request, response);
  const headers = { ...request.headers, "proxy-authorization": auth };
  delete headers["proxy-connection"];
  const upstreamRequest = http.request(
    {
      host,
      port,
      method: request.method,
      path: request.url,
      headers,
    },
    (upstreamResponse) => {
      response.writeHead(upstreamResponse.statusCode, upstreamResponse.headers);
      upstreamResponse.pipe(response);
    },
  );
  upstreamRequest.on("error", () => {
    if (!response.headersSent) response.writeHead(502);
    response.end();
  });
  request.pipe(upstreamRequest);
});

server.on("connect", (request, client, head) => {
  const upstreamRequest = http.request({
    host,
    port,
    method: "CONNECT",
    path: request.url,
    headers: {
      host: request.url,
      "proxy-authorization": auth,
    },
  });

  upstreamRequest.on("connect", (upstreamResponse, tunnel, upstreamHead) => {
    if (upstreamResponse.statusCode !== 200) {
      client.end(`HTTP/1.1 502 Bad Gateway\r\n\r\n`);
      tunnel.destroy();
      return;
    }
    client.write("HTTP/1.1 200 Connection Established\r\n\r\n");
    if (head.length) tunnel.write(head);
    if (upstreamHead.length) client.write(upstreamHead);
    client.pipe(tunnel);
    tunnel.pipe(client);
    client.on("error", () => tunnel.destroy());
    tunnel.on("error", () => client.destroy());
  });
  upstreamRequest.on("error", () => client.destroy());
  client.on("error", () => upstreamRequest.destroy());
  upstreamRequest.end();
});

server.listen(listenPort, "127.0.0.1", () => {
  process.stdout.write(String(server.address().port) + "\n");
});
