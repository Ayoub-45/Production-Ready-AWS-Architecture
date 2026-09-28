module "network" {
  source = "../../modules/network"

  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  app_subnet_cidrs    = var.app_subnet_cidrs
  db_subnet_cidrs     = var.db_subnet_cidrs
}
module "compute" {
  source = "../../modules/compute"

  project_name   = var.project_name
  vpc_id         = module.network.vpc_id
  app_subnet_ids = module.network.app_subnet_ids

  instance_type    = "t3.micro"
  desired_capacity = 2
  min_size         = 2
  max_size         = 4
}
