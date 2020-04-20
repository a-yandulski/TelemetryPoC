## Telemetry PoC with Jaeger and Elasticsearch

### PoC setup

* Download elsaticsearch binaries (https://www.elastic.co/fr/downloads/elasticsearch) and extract them into \elasticsearch folder.
* Execute script [run-all-in-one-with-es.ps1](https://github.com/a-yandulski/TelemetryPoC/blob/master/run-all-in-one-with-es.ps1) to run Elasticsearch and Jaeger components (Agent, Collector, Query).
* Navigate to http://localhost:16686/ in the browser to view Jaeger UI.