output "environment_url" {
  description = "The URL of the deployed environment"
  value       = module.blog_alb.dns_name
}