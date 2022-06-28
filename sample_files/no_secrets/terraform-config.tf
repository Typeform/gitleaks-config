resource "aws_db_instance" "postgres" {
  identifier                 = "${var.environment}-${var.name}"
  engine                     = "postgres"
  engine_version             = "${var.postgres_version}"
  instance_class             = "${var.instance_size}"
  multi_az                   = "${var.multi_az}"
  allocated_storage          = "${var.storage}"
  storage_type               = "gp2"
  username                   = "master"
  password                   = "${random_password.master.result}"
  apply_immediately          = "false"
  skip_final_snapshot        = "true"
  parameter_group_name       = "${aws_db_parameter_group.postgres.name}"
  vpc_security_group_ids     = ["${aws_security_group.postgres.id}"]
  db_subnet_group_name       = "${aws_db_subnet_group.db_subnet.name}"
  backup_window              = "${var.with_backups == "true" ? var.backup_window : ""}"
  backup_retention_period    = "${var.with_backups == "true" ? var.backup_retention_period : 0}"
  maintenance_window         = "${var.with_backups == "true" ? var.maintenance_window : ""}"
  kms_key_id                 = "${var.storage_encryption_arn}"
  storage_encrypted          = "${var.storage_encryption_arn != "" ? true : false}"
  auto_minor_version_upgrade = "false"
  deletion_protection        = "true"

  tags {
    Env  = "${var.environment}"
    Role = "${var.name}-database"
  }
}