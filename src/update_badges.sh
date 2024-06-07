#!/bin/bash

# Define constants
temp_dir=".tmp"
badges_dir="badges"
data_file="${temp_dir}/custom_integrations.json"
default_template_url_file="templates/_default.url"

# Ensure necessary commands are available
required_commands=("curl" "jq")
for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd is required but not installed. Aborting."
        exit 1
    fi
done

# Create temporary and badges directories
mkdir -p "${temp_dir}" "${badges_dir}"

# Ensure cleanup happens even if script exits prematurely
cleanup() {
    rm -rf "${temp_dir}"
}
trap cleanup EXIT

# Download custom integrations JSON
echo "Downloading custom integrations"
if ! curl -s https://analytics.home-assistant.io/custom_integrations.json --output "${data_file}"; then
    echo "Failed to download custom integrations JSON. Aborting."
    exit 1
fi

# Check if the JSON file is valid
if ! jq empty "${data_file}" 2>/dev/null; then
    echo "Invalid JSON file. Aborting."
    exit 1
fi

# Read default template URL
if ! default_template_url=$(<"${default_template_url_file}"); then
    echo "Failed to read default template URL. Aborting."
    exit 1
fi

# Get the list of integrations
integrations=$(jq -r 'keys[]' "${data_file}")

# Iterate over each integration and create a badge
for integration in ${integrations}; do
    installations=$(jq --arg integration "${integration}" '.[$integration].total' "${data_file}")
    echo "Integration ${integration} has ${installations} installations"

    # Check for an integration-specific URL file
    integration_url_file="templates/${integration}.url"
    if [ -f "${integration_url_file}" ]; then
        echo "Using custom template URL for ${integration}"
        template_url=$(<"${integration_url_file}")
    else
        template_url="${default_template_url}"
    fi

    # Replace placeholder with the actual number of installations
    template_url="${template_url//XXXXX/$installations}"

    # Download the badge for the integration
    if ! curl -s "${template_url}" --output "${badges_dir}/${integration}.svg"; then
        echo "Failed to write badge for ${integration}. Continuing."
        continue
    fi
done

echo "Badge creation process completed."
