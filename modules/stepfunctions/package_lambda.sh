#!/bin/bash

# Script to package Lambda functions for deployment
# This script creates ZIP files for each Lambda function

echo "Packaging Lambda functions..."

# Create temporary directory
mkdir -p temp_lambda

# Package validator function
echo "Packaging validator function..."
cp lambda_validator.py temp_lambda/index.py
cd temp_lambda
zip ../lambda_validator.zip index.py
cd ..
rm temp_lambda/index.py

# Package processor function
echo "Packaging processor function..."
cp lambda_processor.py temp_lambda/index.py
cd temp_lambda
zip ../lambda_processor.zip index.py
cd ..
rm temp_lambda/index.py

# Package notifier function
echo "Packaging notifier function..."
cp lambda_notifier.py temp_lambda/index.py
cd temp_lambda
zip ../lambda_notifier.zip index.py
cd ..
rm temp_lambda/index.py

# Clean up
rmdir temp_lambda

echo "Lambda functions packaged successfully!"
echo "Created files:"
echo "  - lambda_validator.zip"
echo "  - lambda_processor.zip"
echo "  - lambda_notifier.zip"

