$root = $PSScriptRoot
$esServer = "http://localhost:9200"
$esUserName = "jaeger"
$esPassword = "PASSWORD"

$env:SPAN_STORAGE_TYPE="elasticsearch"

Start-Process "$root\elasticsearch\bin\elasticsearch.bat" -WorkingDirectory "$root\elasticsearch\bin\"

Start-Sleep 20

$args = "--es.server-urls=$esServer --es.username=$esUserName --es.password=$esPassword --collector.zipkin.http-port=9411"

Start-Process -FilePath "$root\jaeger-collector.exe" -ArgumentList $args -WorkingDirectory "$root"

Start-Sleep 5

$args = "--reporter.grpc.host-port=localhost:14250"

Start-Process -FilePath "$root\jaeger-agent.exe" -ArgumentList $args -WorkingDirectory "$root"

$args = "--es.server-urls=$esServer --es.username=$esUserName --es.password=$esPassword --query.ui-config=$root\ui-config.json"

Start-Process -FilePath "$root\jaeger-query.exe" -ArgumentList $args -WorkingDirectory "$root"