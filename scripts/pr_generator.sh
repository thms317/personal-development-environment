#!/bin/bash

# Get the current branch name
branch_name=$(git rev-parse --abbrev-ref HEAD)

# List of files and directories to ignore
ignore_pattern=" \
    :(exclude)poetry.lock \
    :(exclude)uv.lock \
    :(exclude)assets/* \
    :(exclude)archive/* \
    :(exclude)scratch/* \
"

# Get the diff 
diff_output=$(git diff main...$branch_name $ignore_pattern 2>/dev/null)

# Get the list of changed files with line changes
changed_files=$(git diff --name-only main...$branch_name $ignore_pattern 2>/dev/null)

# Debug info
echo "Branch: $branch_name"
echo "Changed files: $(echo "$changed_files" | wc -l | tr -d ' ')"
echo "Diff size: $(echo "$diff_output" | wc -l | tr -d ' ') lines"

# Get file status info
status_output=$(git diff --name-status main...$branch_name $ignore_pattern 2>/dev/null)

# Extract files by status
new_files=$(echo "$status_output" | grep '^A' | cut -f2 | while read file; do
    lines=$(git diff --numstat main...$branch_name -- "$file" | awk '{print $1}')
    if [ -n "$lines" ] && [ "$lines" -gt 0 ]; then
        echo "$file:$lines"
    fi
done | sort -t: -k2 -rn)

updated_files=$(echo "$status_output" | grep '^M' | cut -f2 | while read file; do
    lines=$(git diff --numstat main...$branch_name -- "$file" | awk '{print $1 + $2}')
    if [ -n "$lines" ] && [ "$lines" -gt 0 ]; then
        echo "$file:$lines"
    fi
done | sort -t: -k2 -rn)

deleted_files=$(echo "$status_output" | grep '^D' | cut -f2 | while read file; do
    lines=$(git diff --numstat main...$branch_name -- "$file" | awk '{print $2}')
    if [ -n "$lines" ] && [ "$lines" -gt 0 ]; then
        echo "$file:$lines"
    fi
done | sort -t: -k2 -rn)

# Check if we got any changes
if [ -z "$changed_files" ]; then
    echo "WARNING: No changes detected between main and $branch_name"
    echo "Verify that both branches exist and have different content"
fi

# Format the file changes into a JSON object
file_changes=$(jq -n \
  --arg new "$new_files" \
  --arg updated "$updated_files" \
  --arg deleted "$deleted_files" \
  '{
    new_files: ($new | split("\n") | map(select(length > 0) | split(":") | {file: .[0], lines_changed: .[1]|tonumber})),
    updated_files: ($updated | split("\n") | map(select(length > 0) | split(":") | {file: .[0], lines_changed: .[1]|tonumber})),
    deleted_files: ($deleted | split("\n") | map(select(length > 0) | split(":") | {file: .[0], lines_changed: .[1]|tonumber}))
  } | with_entries(select(.value != []))')

# Get commit messages with additional info as JSON
commit_messages=$(git log main.."$branch_name" --pretty=format:'{%n  "hash": "%H",%n  "author": "%an",%n  "date": "%ad",%n  "message": "%B"%n},')
commit_messages="[${commit_messages%,}]"

# Check for pull request template
pr_template=""
template_file=$(find . -name "*pull_request_template*.md" -print -quit)
if [ -n "$template_file" ]; then
    pr_template=$(cat "$template_file")
    template_display=${template_file#./}
    echo "Pull request template found: $template_display"
else
    echo "No pull request template found. Using default structure."
    pr_template="# Title\n\n## Description\n\n## Changes\n\n## Checklist\n\n- [ ] Documented\n- [ ] Tested"
fi

# Get the file tree (ignoring irrelevant folders)
file_tree=$(tree -I '.venv|__pycache__|archive|scratch|.databricks|.ruff_cache|.mypy_cache|.pytest_cache|.git|htmlcov|site|dist|.DS_Store|fixtures' -a --noreport)

# Create the pr_instructions.json file
jq -n \
    --argjson instructions '[
        "You are a helpful senior software engineer tasked with writing a comprehensive pull request (PR) message. Please follow these instructions exactly:",
        "Provide a meaningful title for the PR.",
        "Be brief but thorough. Include any relevant information that would help the reviewer understand the changes.",
        "Important: your response should strictly be in the format of a valid Markdown file.",
        "Start with a brief summary of the most significant changes made in this PR.",
        "Stick to the structure of the provided pull_request_template.", 
        "Do not group changes by file_changes and do not mention the number of lines changed. Feel free to ignore files with low lines_changed.",
        "Use bullet points to describe the changes made in this branch.",
        "Interpret commit_messages and use them as additional input if needed.",
        "Do not include any Markdown comments in the final PR message.",
        "Use the following inputs:",
        "file_changes: Changed files categorized by new, updated, or deleted; sorted by lines_changed.",
        "git_diff: The actual git diff for this PR.",
        "commit_messages: Commit messages for this PR that provide additional information.",
        "file_tree: The overall project structure to give context on how these changes fit into it.",
        "branch_name: Provides additional context for the changes (optional).",
        "pull_request_template: The structure of the PR message."
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

echo "Instructions for PR description generation have been saved to: pr_instructions.json"