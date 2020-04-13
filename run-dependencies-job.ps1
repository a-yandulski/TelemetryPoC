$root = $PSScriptRoot
$env:STORAGE="elasticsearch"
$env:ES_NODES="http://localhost:9200"
$env:HADOOP_HOME="$root\hadoop-common\"

& java -jar jaeger-spark-dependencies-0.0.1-SNAPSHOT.jar