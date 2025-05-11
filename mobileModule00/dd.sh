#!/bin/bash


# Function to create a Flutter project
create_flutter_project() {
    local project_name=$1
    echo "Creating Flutter project: $project_name"
    
    # Create project directory if it doesn't exist
    mkdir -p "$project_name"
    
    # Use Flutter CLI to create a new project in the directory
    flutter create --org com.piscine "$project_name"
    
    echo "Project $project_name created successfully!"
}

# Create all required projects according to the Piscine Mobile specifications
create_flutter_project "ex00"
create_flutter_project "ex01"
create_flutter_project "ex02"
create_flutter_project "calculator_app"

echo "All projects have been created in the mobileModule00 directory!"
echo "Project structure:"
echo "- mobileModule00/"
echo "  |- ex00/               (Exercise 00: A basic display)"
echo "  |- ex01/               (Exercise 01: Say Hello to the World)"
echo "  |- ex02/               (Exercise 02: More Buttons)"
echo "  |- calculator_app/     (Exercise 03: It's Alive!)"
echo ""
echo "Remember to implement each exercise according to the requirements!"
echo "You can start by modifying the main.dart file in each project."