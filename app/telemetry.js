
'use strict';

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { PrometheusExporter } = require('@opentelemetry/exporter-prometheus');

const exporter = new PrometheusExporter(
  { port: 9464 }, 
  () => {
    console.log('Prometheus metrics endpoint started');
  }
);

const sdk = new NodeSDK({
  metricReader: exporter,
});

sdk.start();
