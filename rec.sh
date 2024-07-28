#!/bin/bash

# Function to print usage
usage() {
  echo "Usage: $0 -d <domain> [-rl <ratelimit in seconds>] [-js]"
  echo "  -d <domain>            Specify the domain to scan."
  echo "  -rl <ratelimit>        Specify the rate limit in seconds."
  echo "  -js                    Find working JS files from the Wayback Machine and save them in a file."
  exit 1
}

# Check for required arguments
if [ $# -lt 2 ]; then
  usage
fi

# Initialize variables
js_flag=false
ratelimit=0

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
    -js)
      js_flag=true
      shift # past argument
      ;;
    *)
      usage
      ;;
  esac
done

# Check if domain is provided
if [ -z "$domain" ]; then
  usage
fi

# Convert rate limit from seconds to milliseconds if provided
if [ "$ratelimit" -gt 0 ]; then
  ratelimit_ms=$((ratelimit * 1000))
fi

# Function to find JS files from the Wayback Machine
find_js_files() {
  echo "Finding JS files from Wayback Machine for domain: $domain"
  waybackurls "$domain" | grep "\.js$" | sort -u > js_files.txt
  echo "JS files saved to js_files.txt"
  
  if [ "$ratelimit" -gt 0 ]; then
    echo "Running httpx with rate limit: ${ratelimit}s (${ratelimit_ms}ms)"
    cat sorted.txt | waybackurls | grep "\.js$" | httpx -mc 200 -rl "$ratelimit_ms" >> js.txt
  else
    echo "Running httpx without rate limit"
    cat sorted.txt | waybackurls | grep "\.js$" | httpx -mc 200 >> js.txt
  fi
}

# Run subfinder and httprobe
echo "Running subfinder for domain: $domain"
subfinder -d "$domain" | httprobe --prefer-https > sub.txt

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
if [ "$ratelimit" -gt 0 ]; then
  echo "Running fff with rate limit: ${ratelimit}s (${ratelimit_ms}ms)"
  cat sorted.txt | fff -d "$ratelimit_ms" -S -o roots
else
  echo "Running fff without rate limit"
  cat sorted.txt | fff -S -o roots
fi

# Check if js_flag is set and run the JS file finding function
if [ "$js_flag" = true ]; then
  find_js_files
fi

echo "Reconnaissance completed."
