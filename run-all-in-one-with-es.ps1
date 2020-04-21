$root = $PSScriptRoot
$esServer = "http://localhost:9200"
$esUserName = "jaeger"
$esPassword = "PASSWORD"
$env:SPAN_STORAGE_TYPE="elasticsearch"

function Start-Elasticsearch(){

   Write-Host "Starting Elasticsearch server at $esServer"

   Start-Process "$root\elasticsearch\bin\elasticsearch.bat" -WorkingDirectory "$root\elasticsearch\bin\"

   Start-Sleep 20
}

function Start-Collector(){

   Write-Host "Starting Jaeger-Collector"

   $args = "--es.server-urls=$esServer --es.username=$esUserName --es.password=$esPassword --collector.zipkin.http-port=9411 --es-archive.use-aliases=true --es.use-aliases=true"

   Start-Process -FilePath "$root\jaeger-collector.exe" -ArgumentList $args -WorkingDirectory "$root"

   Start-Sleep 5
}

function Start-Agent(){

   Write-Host "Starting Jaeger-Agent"

   $args = "--reporter.grpc.host-port=localhost:14250"

   Start-Process -FilePath "$root\jaeger-agent.exe" -ArgumentList $args -WorkingDirectory "$root"
}

function Start-UI(){

   Write-Host "Starting Jaeger-Query"

   $args = "--es.server-urls=$esServer --es.username=$esUserName --es.password=$esPassword --query.ui-config=$root\ui-config.json --es-archive.use-aliases=true --es.use-aliases=true"

   Start-Process -FilePath "$root\jaeger-query.exe" -ArgumentList $args -WorkingDirectory "$root"
}

function ReIndex-Dependencies(){

   Write-Host "Re-indexing dependencies"

   $date = [System.DateTime]::UtcNow.Date
   $index = "jaeger-dependencies-2020-04-13"
   $newIndex = "jaeger-dependencies-$($date.ToString("yyyy-MM-dd"))"

   # Create new index for current date if one does not exist

   Try
   {
      $response = Invoke-WebRequest -Uri "$esServer/$newIndex" -Method "HEAD" -ErrorAction Stop
      $statusCode = $Response.StatusCode
   }
   Catch
   {
      $statusCode = $_.Exception.Response.StatusCode.value__
   }

   If ($statusCode -eq "404") {
      $body = @{
         source=@{
            index=$index
         };
         dest=@{
            index=$newIndex
         }
      }

      $json = $body | ConvertTo-Json

      Invoke-WebRequest -Uri "$esServer/_reindex" -Method "POST" -Body $json -ContentType "application/json"

      Start-Sleep 5
   }

   # Update timestamp in the index

   $body = @{
      script=@{
         source="ctx._source.timestamp = '$($date.ToString("s"))Z'";
         lang="painless"
      }
   }

   $json = $body | ConvertTo-Json

   Invoke-WebRequest -Uri "$esServer/$newIndex/_update_by_query?conflicts=proceed" -Method "POST" -Body $json -ContentType "application/json"

   # Remove dependencies indexes except the first one / new one

   $indices = Invoke-WebRequest -Uri "$esServer/_cat/indices?format=JSON&h=index" -Method "GET" | ConvertFrom-Json

   Foreach ($idx in $indices) {
      If($idx.Index.StartsWith("jaeger-dependencies-", "CurrentCultureIgnoreCase") -and !($idx.Index -eq $index) -and !($idx.Index -eq $newIndex)) {
         Invoke-WebRequest -Uri "$esServer/$($idx.Index)" -Method "DELETE"
      }
   }
}

Start-Elasticsearch
Start-Collector
Start-Agent
ReIndex-Dependencies
Start-UI

Write-Host "All components started"