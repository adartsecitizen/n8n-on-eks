resource "aws_elasticache_subnet_group" "valkey" {
  name       = "${var.project_name}-valkey-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = local.common_tags
}

resource "aws_elasticache_replication_group" "valkey" {
  replication_group_id         = "${var.project_name}-valkey"
  description                  = "Valkey cluster for n8n queues"
  
  engine               = "valkey"
  engine_version       = var.valkey_version
  node_type            = var.valkey_node_type
  port                 = 6379
  
  num_node_groups         = 1    # 1 shard
  replicas_per_node_group = 1    # 1 replica per shard
  parameter_group_name    = "default.valkey7.cluster.on"
  automatic_failover_enabled = true
  
  subnet_group_name    = aws_elasticache_subnet_group.valkey.name
  security_group_ids   = [aws_security_group.valkey.id]
  
  transit_encryption_enabled = false
  at_rest_encryption_enabled = true
  
  maintenance_window         = "sun:05:00-sun:06:00"
  snapshot_retention_limit   = 1
  snapshot_window           = "03:00-04:00"
  
  tags = local.common_tags
}

resource "aws_security_group" "valkey" {
  name_prefix = "${var.project_name}-valkey-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for ElasticCache"

  ingress {
    description = "Access from EKS private subnets only"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-valkey-sg"
  })
}