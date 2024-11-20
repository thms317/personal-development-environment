#!/bin/bash

# Fetch updates from the remote repository and prune deleted branches
git fetch --prune

# List all branches with their remote counterpart
echo "Local branches:"
git --no-pager branch -vv

# Loop through the local branches that have no remote counterpart
for branch in $(git branch -vv | grep ': gone]' | awk '{print $1}')
do
    # Prompt for confirmation
    read -p "Delete branch '$branch'? (y/n): " answer
    if [[ "$answer" == [Yy]* ]]; then
        echo "Deleting branch: $branch"
        git branch -D "$branch"
    else
        echo "Skipping branch: $branch"
    fi
done

# List the remaining branches
echo "Finished processing branches."
echo "Remaining branches:"
git --no-pager branch -vv
