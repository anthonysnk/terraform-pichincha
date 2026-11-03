# Enable the Terraform ruleset plugin
plugin "terraform" {
  enabled = true
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
  preset  = "all"
  version = "0.12.0"
}

# Rule: Enforce naming conventions for resources
rule "terraform_naming_convention" {
  enabled = true
  # Ensures that resource names follow a standardized naming convention
}

# Rule: Require a minimum Terraform version
rule "terraform_required_version" {
  enabled = true
  # Verifies that the minimum required Terraform version is specified
}

# Rule: Ensure all providers are declared
rule "terraform_required_providers" {
  enabled = true
  # Checks that all required providers are declared in the configuration
}

# Rule: Detect unused declarations
rule "terraform_unused_declarations" {
  enabled = false
  # Identifies variables, resources, or modules that are declared but not used
}

# Rule: Detect deprecated interpolation syntax
rule "terraform_deprecated_interpolation" {
  enabled = true
  # Flags the use of deprecated interpolation syntax in strings
}

# Rule: Detect deprecated index usage
rule "terraform_deprecated_index" {
  enabled = true
  # Flags the use of deprecated index syntax in lists
}

# Rule: Detect deprecated lookup function usage
rule "terraform_deprecated_lookup" {
  enabled = true
  # Flags the use of the deprecated lookup function
}

# Rule: Detect comparisons with empty lists
rule "terraform_empty_list_equality" {
  enabled = true
  # Flags comparisons with empty lists, which may lead to unexpected behavior
}

# Rule: Detect duplicate keys in maps
rule "terraform_map_duplicate_keys" {
  enabled = true
  # Flags duplicate keys in maps, which can cause unexpected behavior
}

# Rule: Ensure modules have pinned sources
rule "terraform_module_pinned_source" {
  enabled = true
  # Ensures that module sources are pinned to specific versions
}

# Rule: Ensure modules have specified versions
rule "terraform_module_version" {
  enabled = true
  # Verifies that modules have a version specified
}

# Rule: Enforce standard module structure
rule "terraform_standard_module_structure" {
  enabled = false
  # Ensures that modules follow a standard directory structure
}
