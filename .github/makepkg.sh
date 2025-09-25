#!/bin/bash

# makepkg.sh - Create AuraFix.zip package with proper directory structure
# This script creates a zip file containing the AuraFix addon files

set -e  # Exit on any error

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Define the output zip file name
OUTPUT_ZIP="AuraFix.zip"

# Define the files to include in the package
FILES=(
    "AuraFix_Config.lua"
    "AuraFix.lua"
    "AuraFix.png"
    "AuraFix.toc"
    "BlizzardEditMode.lua"
)

echo "Creating AuraFix package..."

# Change to project root directory
cd "$PROJECT_ROOT"

# Remove existing zip file if it exists
if [ -f ".vscode/$OUTPUT_ZIP" ]; then
    echo "Removing existing $OUTPUT_ZIP"
    rm ".vscode/$OUTPUT_ZIP"
fi

# Create temporary directory for package structure
TEMP_DIR=$(mktemp -d)
PACKAGE_DIR="$TEMP_DIR/AuraFix"

echo "Creating package structure in $PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# Copy files to package directory
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Adding $file"
        cp "$file" "$PACKAGE_DIR/"
    else
        echo "Warning: $file not found, skipping"
    fi
done

# Create the zip file from the temporary directory
echo "Creating $OUTPUT_ZIP"
cd "$TEMP_DIR"
zip -r "$PROJECT_ROOT/.vscode/$OUTPUT_ZIP" AuraFix/

# Clean up temporary directory
echo "Cleaning up temporary files"
rm -rf "$TEMP_DIR"

echo "Package created successfully: .vscode/$OUTPUT_ZIP"
echo "Contents:"
unzip -l ".vscode/$OUTPUT_ZIP"
# Return to project root
cd "$PROJECT_ROOT"


