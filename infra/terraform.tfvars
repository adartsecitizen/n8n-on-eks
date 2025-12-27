# --- Existing Infrastructure Configuration ---
# Replace these values with your actual AWS resource IDs
existing_cluster_name = "hr-stag-eksdemo1"
existing_vpc_id       = "vpc-07a1625611b2dc5dc"

# --- Project Settings ---
project_name          = "n8n-demo"
region                = "us-east-1"

# --- Optional Database Settings ---
# You can adjust these if you want to save costs or increase performance
db_min_capacity       = 0.5  # Aurora Serverless v2 ACUs (min 0.5)
db_max_capacity       = 2.0
db_engine_version     = "16.6"

# --- Optional Feature Flags ---
# Keep this false initially. Set to true ONLY after you have the ALB DNS name.
create_cloudfront     = false
alb_dns_name          = ""
