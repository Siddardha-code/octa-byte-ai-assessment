# ---------- NETWORKING ----------
module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  environment  = var.environment
}

# ---------- STORAGE (S3 + CloudFront) ----------
module "storage" {
  source       = "./modules/storage"
  project_name = var.project_name
  environment  = var.environment
}

# ---------- DATABASE (RDS) ----------
module "database" {
  source          = "./modules/database"
  project_name    = var.project_name
  environment     = var.environment
  db_username     = var.db_username
  db_password     = var.db_password
  private_subnets = module.networking.private_subnet_ids
  vpc_id          = module.networking.vpc_id
}