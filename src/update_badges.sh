#!/bin/bash

# Define constants
temp_dir=".tmp"
badges_dir="badges"
data_file="${temp_dir}/custom_integrations.json"

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

# Get the list of integrations
integrations=$(jq -r 'keys[]' "${data_file}")

# Read default badge template
if ! default_badge_content=$(<templates/_default.svg); then
    echo "Failed to read default badge template. Aborting."
    exit 1
fi

# Iterate over each integration and create a badge
for integration in ${integrations}; do
    installations=$(jq --arg integration "${integration}" '.[$integration].total' "${data_file}")
    echo "Integration ${integration} has ${installations} installations"

    # Check for an integration-specific template
    integration_template="templates/${integration}.svg"
    if [ -f "${integration_template}" ]; then
        echo "Using custom template for ${integration}"
        if ! badge_content=$(<"${integration_template}"); then
            echo "Failed to read custom template for ${integration}. Using default template."
            badge_content="${default_badge_content}"
        fi
    else
        badge_content="${default_badge_content}"
    fi

    # Replace placeholder with the actual number of installations
    badge_content="${badge_content//XXXXX/$installations}"

    # Write the badge content to the file
    if ! echo -n "$badge_content" > "${badges_dir}/${integration}.svg"; then
        echo "Failed to write badge for ${integration}. Continuing."
    fi
done
