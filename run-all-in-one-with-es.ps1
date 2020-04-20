$root = $PSScriptRoot
$esServer = "http://localhost:9200"
$esUserName = "jaeger"
$esPassword = "PASSWORD"

$env:SPAN_STORAGE_TYPE="elasticsearch"

Write-Host "Starting Elasticsearch server at $esServer"

Start-Process "$root\elasticsearch\bin\elasticsearch.bat" -WorkingDirectory "$root\elasticsearch\bin\"

Start-Sleep 20

Write-Host "Starting Jaeger-Collector"

$args = "--es.server-urls=$esServer --es.username=$esUserName --es.password=$esPassword --collector.zipkin.http-port=9411 --es-archive.use-aliases=true --es.use-aliases=true"

Start-Process -FilePath "$root\jaeger-collector.exe" -ArgumentList $args -WorkingDirectory "$root"

Start-Sleep 5

Write-Host "Starting Jaeger-Agent"

$args = "--reporter.grpc.host-port=localhost:14250"

Start-Process -FilePath "$root\jaeger-agent.exe" -ArgumentList $args -WorkingDirectory "$root"

Write-Host "Updating dependencies index"

$index = "jaeger-dependencies-2020-04-13"
$date = Get-Date -Format o
$body = @{
    script=@{
       source="ctx._source.timestamp = '$date'";
       lang="painless"
    }
 }

$json = $body | ConvertTo-Json

Invoke-WebRequest -Uri "$esServer/$index/_update_by_query?conflicts=proceed" -Method "POST" -Body $json -ContentType "application/json"

Write-Host "Starting Jaeger-Query"

$args = "--es.server-urls=$esServer --es.username=$esUserName --es.password=$esPassword --query.ui-config=$root\ui-config.json --es-archive.use-aliases=true --es.use-aliases=true"

Start-Process -FilePath "$root\jaeger-query.exe" -ArgumentList $args -WorkingDirectory "$root"

Write-Host "All components started"