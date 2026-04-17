output "pedidos_stream_name" { value = aws_kinesis_stream.pedidos.name }
output "pedidos_stream_arn" { value = aws_kinesis_stream.pedidos.arn }
output "sensores_stream_name" { value = aws_kinesis_stream.sensores.name }
output "sensores_stream_arn" { value = aws_kinesis_stream.sensores.arn }