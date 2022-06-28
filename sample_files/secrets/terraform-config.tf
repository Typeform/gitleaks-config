resource "kubernetes_secret" "insights_dlq_db_credentials" {

  metadata {
    name      = "insights-dlq-db-credentials"
    namespace = var.functions_namespace
  }

  data = {
    username = "typeform"
    password = "a3406ece8ff2ce6fb3ba6c3e89d918e2fe4dc"
  }
}

data "aws_ssm_parameter" "insights_dlq_db_password" {
  name = "${var.ssm_prefix}/secrets/insights_dlq_db_password"
}