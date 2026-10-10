output "random" {
  description = "The random part Azure/naming 0.4.3 appended to every name_unique."
  value       = substr(join("", [random_string.first_letter.result, random_string.main.result]), 0, 4)
}
