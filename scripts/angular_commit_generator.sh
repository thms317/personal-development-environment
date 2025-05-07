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
diff_output=$(git diff --cached "origin/$branch_name" $ignore_pattern 2>/dev/null)

# Get the list of changed files with line changes
changed_files=$(git diff --cached --name-only "origin/$branch_name" $ignore_pattern 2>/dev/null)

# Debug info
echo "Branch: $branch_name"
echo "Changed files: $(echo "$changed_files" | wc -l | tr -d ' ')"
echo "Diff size: $(echo "$diff_output" | wc -l | tr -d ' ') lines"

# Get file status info
status_output=$(git diff --cached --name-status "origin/$branch_name" $ignore_pattern 2>/dev/null)

# Extract files by status
new_files=$(echo "$status_output" | grep '^A' | cut -f2 | while read file; do
    lines=$(git diff --cached --numstat "origin/$branch_name" -- "$file" | awk '{print $1}')
    if [ -n "$lines" ] && [ "$lines" -gt 0 ]; then
        echo "$file:$lines"
    fi
done | sort -t: -k2 -rn)

updated_files=$(echo "$status_output" | grep '^M' | cut -f2 | while read file; do
    lines=$(git diff --cached --numstat "origin/$branch_name" -- "$file" | awk '{print $1 + $2}')
    if [ -n "$lines" ] && [ "$lines" -gt 0 ]; then
        echo "$file:$lines"
    fi
done | sort -t: -k2 -rn)

deleted_files=$(echo "$status_output" | grep '^D' | cut -f2 | while read file; do
    lines=$(git diff --cached --numstat "origin/$branch_name" -- "$file" | awk '{print $2}')
    if [ -n "$lines" ] && [ "$lines" -gt 0 ]; then
        echo "$file:$lines"
    fi
done | sort -t: -k2 -rn)

# Check if we got any changes
if [ -z "$changed_files" ]; then
    echo "WARNING: No changes detected in staged files compared to origin/$branch_name"
    echo "Make sure you have staged your changes with 'git add' and that origin/$branch_name exists"
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

# Get the file tree (ignoring irrelevant folders)
file_tree=$(tree -I '.venv|__pycache__|archive|scratch|.databricks|.ruff_cache|.mypy_cache|.pytest_cache|.git|htmlcov|site|dist|.DS_Store|fixtures' -a --noreport)

# Create the pr_instructions.json file
jq -n \
    --argjson instructions '[
        "You are a senior software engineer and are to write a commit message for the staged files, following the Angular Commit Format.",
        "Each commit message consists of a header, a body, and a footer: <header><BLANK LINE><body><BLANK LINE><footer>",
        "- The header is mandatory and must conform to the Commit Message Header format (described below).",
        "- The body is mandatory for all commits except for those of type `docs`. When the body is present it must be at least 20 characters long and must conform to the Commit Message Body format.",
        "- The footer is optional. The Commit Message Footer format describes what the footer is used for and the structure it must have.",
        "Commit Message Header:",
        "<type>(<scope>): <short summary>",
        "│       │             │",
        "│       │             └─⫸ Summary in present tense. Not capitalized. No period at the end.",
        "│       │",
        "│       └─⫸ Commit Scope (optional): <noun describing a section of the codebase surrounded by parenthesis>",
        "│",
        "└─⫸ Commit Type: build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test",
        "The <type> and <summary> fields are mandatory, the (<scope>) field is optional.",
        "EXCLUSIVELY pick one the following commit types:",
        "- build:    Changes that affect the build system or external dependencies",
        "- chore:    Maintenance tasks that do not modify source code or tests",
        "- ci:       Changes to our CI configuration files and scripts",
        "- docs:     Documentation only changes",
        "- feat:     A new feature",
        "- fix:      A bug fix",
        "- perf:     A code change that improves performance",
        "- refactor: A code change that neither fixes a bug nor adds a feature",
        "- revert:   Revert a previous commit, typically to fix issues or errors",
        "- style:    Changes that do not affect code meaning, only its format or structure",
        "- test:     Adding missing tests or correcting existing tests",
        "If included, the (<scope>) field MUST consist of a noun describing a section of the codebase surrounded by parenthesis, e.g., fix(parser): or feat(compiler):.",
        "Commit Message Body: explain the motivation for the change in the commit message body. This commit message should explain why you are making the change. You can include a comparison of the previous behavior with the new behavior in order to illustrate the impact of the change.",
        "Commit Message Footer: the footer can contain information about breaking changes and deprecations and is also the place to reference GitHub issues, Jira tickets, and other PRs that this commit closes or is related to.",
        "Important: Use the summary field to provide a succinct description of the change: use the imperative, present tense: `change` not `changed` nor `changes`, do not capitalize the first letter, no dot at the end."
    ]' \
    --argjson file_changes "$file_changes" \
    --arg diff "$diff_output" \
    --arg file_tree "$file_tree" \
    '{
        instructions: $instructions,
        file_changes: $file_changes,
        git_diff: $diff | split("\n") | map(select(length > 0)),
        file_tree: $file_tree | split("\n") | map(select(length > 0))
    }' > angular_commit_instructions.json
    
   
echo "Instructions for Angular commit message generation have been saved to: angular_commit_instructions.json"
