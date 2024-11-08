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
ignore_params=()
for ignore in "${ignore_list[@]}"; do
    ignore_params+=(":!$ignore")
done

# Get the diff (ignoring ignore_list)
diff_output=$(git diff --cached "origin/$branch_name" "${ignore_params[@]}" 2>/dev/null)

# Get the list of changed files with line changes (ignoring ignore_list)
changed_files=$(git diff --cached "origin/$branch_name" --name-only "${ignore_params[@]}" 2>/dev/null)

# Function to safely get line changes for a file
get_line_changes() {
    local file="$1"
    local status="$2"
    local lines=""
    
    if [ "$status" = "A" ]; then
        lines=$(git diff --cached "origin/$branch_name" --numstat -- "$file" "${ignore_params[@]}" 2>/dev/null | awk '{print $1}')
    elif [ "$status" = "M" ]; then
        lines=$(git diff --cached "origin/$branch_name" --numstat -- "$file" "${ignore_params[@]}" 2>/dev/null | awk '{print $1 + $2}')
    elif [ "$status" = "D" ]; then
        lines=$(git diff --cached "origin/$branch_name" --numstat -- "$file" "${ignore_params[@]}" 2>/dev/null | awk '{print $2}')
    fi
    
    if [ -z "$lines" ]; then
        lines=0
    fi
    echo "$file:$lines"
}

# Categorize changed files with line counts
new_files=$(git diff --name-status --cached "origin/$branch_name" "${ignore_params[@]}" 2>/dev/null | grep '^A' | cut -f2 | while read -r file; do
    get_line_changes "$file" "A"
done | sort -t: -k2 -rn)

updated_files=$(git diff --name-status --cached "origin/$branch_name" "${ignore_params[@]}" 2>/dev/null | grep '^M' | cut -f2 | while read -r file; do
    get_line_changes "$file" "M"
done | sort -t: -k2 -rn)

deleted_files=$(git diff --name-status --cached "origin/$branch_name" "${ignore_params[@]}" 2>/dev/null | grep '^D' | cut -f2 | while read -r file; do
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
    
   
echo "Instructions for Angular commit message generation have been saved to angular_commit_instructions.json"
