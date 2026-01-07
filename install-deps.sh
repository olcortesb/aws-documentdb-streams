#!/bin/bash

echo "Installing Lambda dependencies..."

# Writer Lambda
echo "Installing writer dependencies..."
cd lambda/writer
pip install -r requirements.txt -t .
cd ../..

# Stream Processor Lambda  
echo "Installing stream-processor dependencies..."
cd lambda/stream-processor
pip install -r requirements.txt -t .
cd ../..

echo "Dependencies installed. Run 'terraform apply' to update Lambdas."