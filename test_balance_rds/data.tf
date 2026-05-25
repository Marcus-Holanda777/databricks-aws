data "dns_a_record_set" "postgres_internal_ip" {
  depends_on = [aws_db_instance.postgres_db]
  host       = element(split(":", aws_db_instance.postgres_db.endpoint), 0)
}