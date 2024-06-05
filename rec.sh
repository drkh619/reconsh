#!/bin/bash

# Function to print usage
usage() {
  echo "Usage: $0 -d <domain> -rl <ratelimit in seconds>"
  exit 1
}

# Check for required arguments
if [ $# -lt 4 ]; then
  usage
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -d)
      domain="$2"
      shift # past argument
      shift # past value
      ;;
    -rl)
      ratelimit="$2"
      shift # past argument
      shift # past value
      ;;
    *)
      usage
      ;;
  esac
done

# Check if both domain and ratelimit are provided
if [ -z "$domain" ] || [ -z "$ratelimit" ]; then
  usage
fi

# Convert rate limit from seconds to milliseconds
ratelimit_ms=$((ratelimit * 1000))

# Run subfinder and httprobe
echo "Running subfinder for domain: $domain"
subfinder -d "$domain" | httprobe > sub.txt

# Sort and filter the results
echo "Sorting and filtering results..."
sort -r sub.txt | awk -F/ '
{
  domain = $3
  protocol = $1
  if (protocol == "https:") {
    https_seen[domain] = $0
  }
  if (protocol == "http:" && !https_seen[domain]) {
    http_seen[domain] = $0
  }
}
END {
  for (domain in https_seen) {
    print https_seen[domain]
  }
  for (domain in http_seen) {
    if (!https_seen[domain]) {
      print http_seen[domain]
    }
  }
}' | tee sorted.txt

# Run fff with specified rate limit
echo "Running fff with rate limit: ${ratelimit}s (${ratelimit_ms}ms)"
cat sorted.txt | fff -d "$ratelimit_ms" -S -o roots

echo "Reconnaissance completed."
