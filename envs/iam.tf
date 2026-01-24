/************************************************************
Identity Domain
************************************************************/
resource "oci_identity_domain" "this" {
  compartment_id     = oci_identity_compartment.workload.id
  display_name       = "verification"
  description        = "For Verification"
  license_type       = "free"
  home_region        = "ap-tokyo-1"
  state              = "ACTIVE"
  admin_email        = null
  admin_first_name   = null
  admin_last_name    = null
  admin_user_name    = null
  is_hidden_on_login = false
  defined_tags       = local.common_defined_tags
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      echo Deactive

      oci iam domain deactivate \
      --domain-id ${self.id} \
      --profile ADMIN --auth security_token
      
      echo Please wait Deactive
      sleep 20
    EOT
  }
}

/************************************************************
Remote Region Disaster Recovery
************************************************************/
resource "oci_identity_domain_replication_to_region" "this_osaka" {
  domain_id      = oci_identity_domain.this.id
  replica_region = "ap-osaka-1"
}

/************************************************************
IAM User
************************************************************/
# 「oci_identity_user」を使用する場合はルートコンパートメントのDefaultアイデンティティドメインにしか作成できない
# 「oci_identity_domains_user」を使用すれば、指定のアイデンティティドメインに作成可能
resource "oci_identity_domains_user" "this" {
  active                       = true
  attribute_sets               = null
  attributes                   = null
  authorization                = null
  display_name                 = "hoge fuga"
  force_delete                 = true
  idcs_endpoint                = oci_identity_domain.this.url
  resource_type_schema_version = null
  schemas = [
    "urn:ietf:params:scim:schemas:core:2.0:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:OCITags",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:capabilities:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:user:User"
  ]
  user_name = "FizzBuzz"
  emails {
    type    = "work"
    value   = var.user_email
    primary = true
  }
  emails {
    type  = "recovery"
    value = var.user_email
  }
  name {
    family_name = "fuga"
    formatted   = "hoge fuga"
    given_name  = "hoge"
  }
  urnietfparamsscimschemasoracleidcsextension_oci_tags {
    defined_tags {
      namespace = oci_identity_tag_namespace.common.name
      key       = oci_identity_tag.key_managedbyterraform.name
      value     = "true"
    }
    defined_tags {
      namespace = oci_identity_tag_namespace.common.name
      key       = oci_identity_tag.key_env.name
      value     = "prd"
    }
  }
  urnietfparamsscimschemasoracleidcsextensioncapabilities_user {
    can_use_api_keys                 = true
    can_use_auth_tokens              = true
    can_use_console                  = false
    can_use_console_password         = true
    can_use_customer_secret_keys     = true
    can_use_db_credentials           = true
    can_use_oauth2client_credentials = true
    can_use_smtp_credentials         = true
  }
  urnietfparamsscimschemasoracleidcsextensionuser_user {
    account_recovery_required                  = false
    bypass_notification                        = false
    do_not_show_getting_started                = false
    is_authentication_delegated                = false
    is_federated_user                          = false
    is_group_membership_normalized             = false
    is_group_membership_synced_to_users_groups = false
    preferred_ui_landing_page                  = "MyApps"
    service_user                               = false
    user_flow_controlled_by_external_client    = false
  }
  lifecycle {
    ignore_changes = [
      schemas,
      urnietfparamsscimschemasoracleidcsextension_oci_tags
    ]
  }
}

/************************************************************
IAM Group
************************************************************/
# 「oci_identity_group」を使用する場合はルートコンパートメントのDefaultアイデンティティドメインにしか作成できない
# 「oci_identity_domains_group」を使用すれば、指定のアイデンティティドメインに作成可能
resource "oci_identity_domains_group" "this" {
  attribute_sets               = null
  attributes                   = null
  authorization                = null
  display_name                 = "verify_admin"
  force_delete                 = true
  idcs_endpoint                = oci_identity_domain.this.url
  resource_type_schema_version = null
  schemas = [
    "urn:ietf:params:scim:schemas:core:2.0:Group",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:OCITags"
  ]
  members {
    type  = "User"
    value = oci_identity_domains_user.this.id
  }
  urnietfparamsscimschemasoracleidcsextensiondynamic_group {
    membership_type = "static"
  }
  urnietfparamsscimschemasoracleidcsextension_oci_tags {
    defined_tags {
      namespace = oci_identity_tag_namespace.common.name
      key       = oci_identity_tag.key_managedbyterraform.name
      value     = "true"
    }
    defined_tags {
      namespace = oci_identity_tag_namespace.common.name
      key       = oci_identity_tag.key_env.name
      value     = "prd"
    }
  }
  lifecycle {
    ignore_changes = [
      schemas,
      members,
      urnietfparamsscimschemasoracleidcsextension_oci_tags
    ]
  }
}

/************************************************************
IAM Policy - for Group
************************************************************/
resource "oci_identity_policy" "group_admin" {
  compartment_id = oci_identity_compartment.workload.id
  description    = "Privileges Administrator"
  name           = "admin-privileges-policy"
  statements = [
    format("allow group %s/%s to manage all-resources in compartment %s",
      oci_identity_domain.this.display_name,
      oci_identity_domains_group.this.display_name,
      oci_identity_compartment.workload.name
    ),
  ]
  defined_tags = local.common_defined_tags
}