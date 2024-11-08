#!/bin/bash

# Get the current branch name
branch_name=$(git rev-parse --abbrev-ref HEAD)

# List of files and directories to ignore
ignore_list=(
    "poetry.lock"
    "assets/*"
    "archive/*"
    "scratch/*"
)

# Build the ignore parameters for git diff
ignore_params=""
for ignore in "${ignore_list[@]}"; do
    ignore_params+=" ':!$ignore'"
done

# Function to safely execute git commands with ignore list
safe_git_command() {
    eval "$@ $ignore_params"
}

# Get the diff (ignoring ignore_list)
diff_output=$(safe_git_command "git diff main...$branch_name" 2>/dev/null)

# Get the list of changed files with line changes (ignoring ignore_list)
changed_files=$(safe_git_command "git diff main...$branch_name --name-only" 2>/dev/null)

# Function to safely get line changes for a file
get_line_changes() {
    local file="$1"
    local status="$2"
    local lines
    
    if [ "$status" = "A" ]; then
        lines=$(safe_git_command "git diff main...$branch_name --numstat \"$file\"" 2>/dev/null | awk '{print $1}')
    elif [ "$status" = "M" ]; then
        lines=$(safe_git_command "git diff main...$branch_name --numstat \"$file\"" 2>/dev/null | awk '{print $1 + $2}')
    elif [ "$status" = "D" ]; then
        lines=$(safe_git_command "git diff main...$branch_name --numstat \"$file\"" 2>/dev/null | awk '{print $2}')
    fi
    
    if [ -z "$lines" ]; then
        lines=0
    fi
    echo "$file:$lines"
}

# Categorize changed files with line counts
new_files=$(safe_git_command "git diff --name-status main...$branch_name" 2>/dev/null | grep '^A' | cut -f2 | while read file; do
    get_line_changes "$file" "A"
done | sort -t: -k2 -rn)

updated_files=$(safe_git_command "git diff --name-status main...$branch_name" 2>/dev/null | grep '^M' | cut -f2 | while read file; do
    get_line_changes "$file" "M"
done | sort -t: -k2 -rn)

deleted_files=$(safe_git_command "git diff --name-status main...$branch_name" 2>/dev/null | grep '^D' | cut -f2 | while read file; do
    get_line_changes "$file" "D"
done | sort -t: -k2 -rn)

# Format the file changes into a JSON object, filtering out entries with lines_changed equal to 0
file_changes=$(jq -n \
  --arg new "$new_files" \
  --arg updated "$updated_files" \
  --arg deleted "$deleted_files" \
  '{
    new_files: ($new | split("\n") | map(select(length > 0) | split(":") | {file: .[0], lines_changed: .[1]|tonumber}) | map(select(.lines_changed > 0))),
    updated_files: ($updated | split("\n") | map(select(length > 0) | split(":") | {file: .[0], lines_changed: .[1]|tonumber}) | map(select(.lines_changed > 0))),
    deleted_files: ($deleted | split("\n") | map(select(length > 0) | split(":") | {file: .[0], lines_changed: .[1]|tonumber}) | map(select(.lines_changed > 0)))
  } | with_entries(select(.value != []))')

# Get commit messages with additional info as JSON
commit_messages=$(git log main.."$branch_name" --pretty=format:'{%n  "hash": "%H",%n  "author": "%an",%n  "date": "%ad",%n  "message": "%B"%n},')
commit_messages="[${commit_messages%,}]"

# Check for pull request template
pr_template=""
template_file=$(find . -name "*pull_request_template*.md" -print -quit)
if [ -n "$template_file" ]; then
    pr_template=$(cat "$template_file")
    echo "Pull request template found: $template_file"
else
    echo "No pull request template found. Using default structure."
    pr_template="# Title\n\n## Description\n\n## Issues\n\n## Checklist\n\n- [ ] Documented\n- [ ] Tested"
fi

# Get the file tree (ignoring irrelevant folders)
file_tree=$(tree -I '.venv|__pycache__|archive|scratch|.databricks|.ruff_cache|.mypy_cache|.pytest_cache|.git|htmlcov|site|dist|.DS_Store|fixtures' -a --noreport)

# Create the pr_instructions.json file
jq -n \
    --argjson instructions '[
        "You are a helpful senior software engineer tasked with writing a comprehensive pull request (PR) message. Please follow these instructions exactly:",
        "Title: Provide a meaningful title for the PR.",
        "Summary: Start with a brief summary of the most significant changes made in this PR.",
        "Template: Use the provided pull request template.",
        "File Changes: Do not group changes by file_changes and do not mention the number of lines changed. Feel free to ignore files with low lines_changed.",
        "Bullet Points: Use bullet points to describe the changes made in this branch.",
        "Commit Messages: Interpret commit_messages and use them as additional input if helpful.",
        "Clarity: Be brief but thorough. Include any relevant information that would help the reviewer understand the changes.",
        "Format: Your response should strictly be in the format of a valid Markdown file.",
        "No Comments: Do not include any Markdown comments in the final PR message.",
        "Adherence: Stick strictly to the provided template and these instructions.",
        "Use the following inputs:",
        "file_changes: Categorized by new, updated, or deleted; sorted by lines_changed.",
        "git_diff: The actual changes made in this PR.",
        "commit_messages: Commit messages for this PR that provide additional information.",
        "file_tree: The overall project structure to give context on how these changes fit into it.",
        "Branch Name: Provides additional context for the changes (optional)."
    ]' \
    --argjson file_changes "$file_changes" \
    --arg diff "$diff_output" \
    --arg file_tree "$file_tree" \
    --arg pr_template "$pr_template" \
    --arg branch_name "$branch_name" \
    --arg commit_messages "$commit_messages" \
    '{
        instructions: $instructions,
        file_changes: $file_changes,
        git_diff: $diff | split("\n") | map(select(length > 0)),
        pull_request_template: $pr_template | split("\n") | map(select(length > 0)),
        branch_name: $branch_name,
        file_tree: $file_tree | split("\n") | map(select(length > 0)),
        commit_messages: $commit_messages | split("\n") | map(select(length > 0))
    }' > pr_instructions.json

echo "Instructions for PR description generation have been saved to pr_instructions.json"