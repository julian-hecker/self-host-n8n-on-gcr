# Load variables from terraform.tfvars
TFVARS_FILE="terraform/terraform.tfvars"

get_tfvar() {
    grep "^$1" "$TFVARS_FILE" | awk -F'=' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' | tr -d '"'
}

REGION=$(get_tfvar "gcp_region")
PROJECT_ID=$(get_tfvar "gcp_project_id")
N8N_SERVICE_NAME=$(get_tfvar "cloud_run_service_name")
ARTIFACT_REPO_NAME=$(get_tfvar "artifact_repo_name")

# Set correct GCP Project ID
gcloud config set project $PROJECT_ID

# Authenticate Docker to Google Artifact Registry
gcloud auth configure-docker $REGION-docker.pkg.dev

# Pull the latest n8n image
docker pull n8nio/n8n:latest

# Rebuild your custom image
docker build --platform linux/amd64 -t $REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO_NAME/$N8N_SERVICE_NAME:latest .

# Push to your artifact registry
docker push $REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO_NAME/$N8N_SERVICE_NAME:latest

# Redeploy your Cloud Run service
gcloud run services update $N8N_SERVICE_NAME \
    --image=$REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REPO_NAME/$N8N_SERVICE_NAME:latest \
    --region=$REGION
