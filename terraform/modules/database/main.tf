# RDS needs at least 2 subnets in different AZs — this groups them
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Environment = var.environment
  }
}

# Security group — controls who can talk to RDS
# Only allowing traffic from within the VPC, not from internet
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow PostgreSQL access from within VPC only"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432        # PostgreSQL default port
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]  # only VPC internal traffic
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
  }
}

# The actual RDS instance
resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-postgres"
  engine            = "postgres"
  engine_version    = "16.6"
  instance_class    = "db.t3.micro"   # cheapest option, fine for this assignment
  allocated_storage = 20              # 20 GB

  db_name  = "appdb"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Important security settings
  publicly_accessible = false   # never expose RDS to internet
  skip_final_snapshot = true    # set to false in real prod — creates backup on destroy

  # Encryption at rest
  storage_encrypted = true

  # Automatic backups — keeps 7 days of backups
  backup_retention_period = 7
  backup_window           = "03:00-04:00"  # runs at 3am UTC daily

  # Maintenance window — minor version updates
  maintenance_window = "Mon:04:00-Mon:05:00"

  tags = {
    Name        = "${var.project_name}-postgres"
    Environment = var.environment
  }
}
