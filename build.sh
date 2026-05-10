#!/bin/bash
# Builds index.html from the template and deploys to S3 + invalidates CloudFront.
# Usage: ./build.sh [--no-deploy]

set -e
cd "$(dirname "$0")"

AWS_PROFILE_NAME="${AWS_PROFILE_NAME:-vsc-sso}"
S3_BUCKET="trip.cloudstreamapp.com"
CLOUDFRONT_DIST_ID="E1OIK1KDTNNAO"

if [ ! -f .env ]; then
  echo "Error: .env file not found. Create one with GOOGLE_MAPS_API_KEY=your_key"
  exit 1
fi

source .env

if [ -z "$GOOGLE_MAPS_API_KEY" ] || [ "$GOOGLE_MAPS_API_KEY" = "YOUR_KEY_HERE" ]; then
  echo "Error: Set your Google Maps API key in .env"
  exit 1
fi

sed "s/__GOOGLE_MAPS_API_KEY__/$GOOGLE_MAPS_API_KEY/g" index.template.html > index.html
echo "✓ Built index.html"

if [ "$1" = "--no-deploy" ]; then
  echo "Skipping deploy (--no-deploy)."
  exit 0
fi

if ! aws sts get-caller-identity --profile "$AWS_PROFILE_NAME" >/dev/null 2>&1; then
  echo "AWS SSO session expired. Running: aws sso login --profile $AWS_PROFILE_NAME"
  aws sso login --profile "$AWS_PROFILE_NAME"
fi

aws s3 cp index.html "s3://$S3_BUCKET/index.html" \
  --profile "$AWS_PROFILE_NAME" \
  --content-type "text/html; charset=utf-8" \
  --cache-control "no-cache"
echo "✓ Uploaded to s3://$S3_BUCKET/"

INVALIDATION_ID=$(aws cloudfront create-invalidation \
  --distribution-id "$CLOUDFRONT_DIST_ID" \
  --paths "/index.html" "/" \
  --profile "$AWS_PROFILE_NAME" \
  --query 'Invalidation.Id' \
  --output text)
echo "✓ CloudFront invalidation queued: $INVALIDATION_ID"
echo "Live at https://trip.cloudstreamapp.com (typically updates within ~30s)"
