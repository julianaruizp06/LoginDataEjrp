output "pedidos_firehose_name"  { value = aws_kinesis_firehose_delivery_stream.pedidos.name }
output "sensores_firehose_name" { value = aws_kinesis_firehose_delivery_stream.sensores.name }