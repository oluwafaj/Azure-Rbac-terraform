output "group_object_ids" {
  description = "Object IDs of the created Entra ID groups"
  value = {
    for k, g in azuread_group.teams : k => g.object_id
  }
}

output "user_principal_names" {
  description = "Created User Principal Names (UPNs)"
  value = {
    for k, u in azuread_user.team_users : k => u.user_principal_name
  }
}

output "initial_user_passwords" {
  description = "Generated initial passwords for the 9 users (run: terraform output -json initial_user_passwords)"
  value = {
    for k, p in random_password.user_passwords : k => p.result
  }
  sensitive = true
}
