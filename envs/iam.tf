/************************************************************
IAM User
************************************************************/
# 「oci_identity_user」を使用する場合はルートコンパートメントのDefaultアイデンティティドメインにしか作成できない
# 「oci_identity_domains_user」を使用すれば、指定のアイデンティティドメインに作成可能
resource "oci_identity_user" "this" {
  compartment_id = var.tenancy_ocid
  description    = "User for Validation"
  name           = "FizzBuzz"
  email          = var.user_email
}

/************************************************************
IAM Group
************************************************************/
# 「oci_identity_group」を使用する場合はルートコンパートメントのDefaultアイデンティティドメインにしか作成できない
# 「oci_identity_domains_group」を使用すれば、指定のアイデンティティドメインに作成可能
resource "oci_identity_group" "this" {
  compartment_id = var.tenancy_ocid
  name           = "Validation Admin Group"
  description    = "Group for Validation"
}

resource "oci_identity_user_group_membership" "this" {
  group_id = oci_identity_group.this.id
  user_id  = oci_identity_user.this.id
}

/************************************************************
IAM Policy - for Group
************************************************************/
resource "oci_identity_policy" "group_admin" {
  compartment_id = var.tenancy_ocid
  description    = "Privileges Administrator"
  name           = "admin-privileges-policy"
  statements = [
    format("allow group Default/'%s' to manage all-resources in tenancy",
      oci_identity_group.this.name
    ),
  ]
}