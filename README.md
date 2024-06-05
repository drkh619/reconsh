# Recon Tool

This is a simple reconnaissance tool that automates the process of finding and probing subdomains, sorting and filtering the results to prefer HTTPS over HTTP, and running a final check with `fff`.

## Features

- Uses `subfinder` to find subdomains.
- Probes subdomains using `httprobe`.
- Sorts and filters the results to prefer HTTPS over HTTP.
- Runs `fff` with a specified rate limit.

## Prerequisites

Make sure you have the following tools installed:

- `subfinder`
- `httprobe`
- `fff`
- `awk`

## Installation

1. Clone this repository or download the `recon.sh` script.
2. Make the script executable:

   ```bash
   chmod +x recon.sh
   ```

## Usage
```bash
./recon.sh -d <domain> -rl <ratelimit in seconds>
```

## Example
```bash
./recon.sh -d example.com -rl 5
```
