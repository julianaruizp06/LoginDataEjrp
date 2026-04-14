output "glue_role_arn"     { value = aws_iam_role.glue.arn }
output "firehose_role_arn" { value = aws_iam_role.firehose.arn }
output "analyst_role_arn"  { value = aws_iam_role.analyst.arn }