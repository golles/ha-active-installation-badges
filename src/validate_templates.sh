#!/bin/bash

# Define constants
directory="templates"
search_string="XXXXX"

# Loop through each .url file in the directory
for file in "$directory"/*.url; do
  # Check if the file contains the search string
  if ! grep -q "$search_string" "$file"; then
    # Output the filename to the console and exit
    echo "The file '$file' does not contain the string '$search_string'."
    exit 1
  fi
done

# If all files contain the string, print a success message
echo "All .url files contain the string '$search_string'."
