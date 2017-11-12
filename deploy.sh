#!/usr/bin/env bash

git config user.name "$(git show -s --format='%an')"
git config user.email "$(git show -s --format='%ae')"
git remote add deploy "git@github.com:$TRAVIS_REPO_SLUG"
git checkout --orphan "$PUSH_BRANCH"
git rm --cached -rf .
git add -f repo/
git commit -m "Repo from commit $TRAVIS_COMMIT"

eval $(ssh-agent)
ssh-add deploy_key
git push -f deploy "$PUSH_BRANCH"
