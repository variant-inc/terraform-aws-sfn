output "sfn_arn" {
  value       = aws_sfn_state_machine.sfn.arn
  description = "ARN of newly created state machine."
}