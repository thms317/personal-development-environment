#!/bin/bash

# Fetch updates from the remote repository and prune deleted branches
git fetch --prune

# List all branches with their remote counterpart
echo "Local branches:"
git --no-pager branch -vv

# Loop through the local branches that have no remote counterpart and delete them
for branch in $(git branch -vv | grep ': gone]' | awk '{print $1}')
do
    echo "Deleting branch: $branch"
    git branch -d $branch
done

# List the remaining branches
echo "Deleted branches with no remote counterpart."
echo "Remaining branches:"
git --no-pager branch -vv