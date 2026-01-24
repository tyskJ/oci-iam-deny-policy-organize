/************************************************************
Compartment - workload
************************************************************/
resource "oci_identity_compartment" "workload" {
  compartment_id = var.tenancy_ocid
  name           = "oci-iam-deny-policy-organize"
  description    = "For OCI IAM Deny Policy Organize"
  enable_delete  = true
}