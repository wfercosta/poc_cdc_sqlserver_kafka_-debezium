module "iamsr" {
  source = "./_modules/aws-iamsr"

  replacement_vars = {
    account_id = local.account_id
    region     = local.region
  }

  policies = {
    policy-get-secret-value = "./_iamsr/policies/policy-get-secret-value.tftpl",
    policy-msk-connect-s3   = "./_iamsr/policies/policy-msk-connect-s3.tftpl",
    policy-msk-iam-auth     = "./_iamsr/policies/policy-msk-iam-auth.tfpl",
  }

  roles = {
    bastion-host = {
      trust_role = "./_iamsr/assume_roles/trust-ec2.tftpl"
      policies_attachments = [
        "arn:aws:iam::${local.account_id}:policy/policy-get-secret-value",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]
    },
    msk-connect-debezium = {
      trust_role = "./_iamsr/assume_roles/trust-kafka-connect.tftpl"
      policies_attachments = [
        "arn:aws:iam::${local.account_id}:policy/policy-msk-connect-s3",
        "arn:aws:iam::${local.account_id}:policy/policy-msk-iam-auth",
        "arn:aws:iam::${local.account_id}:policy/policy-get-secret-value"
      ]
    }
  }
}
