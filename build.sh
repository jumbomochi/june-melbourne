#!/bin/bash
# Reads .env and injects GOOGLE_MAPS_API_KEY into index.template.html → index.html

set -e
cd "$(dirname "$0")"

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
echo "Built index.html with API key injected."
