#!/bin/bash

# Exit if anything goes wrong
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

GITHUB_PAGES_BRANCH="gh-pages"

PHL_BRANCH="gh-pages"
PHL_REMOTE_NAME="origin"
PHL_REMOTE_URL="git@github.com:barik/kash-tess-wedding.git"

SAN_BRANCH="san"
SAN_REMOTE_NAME="san"
SAN_REMOTE_URL="git@github.com:barik/kash-tess-wedding-san.git"
SAN_HOST="www.tessandkash.com"

CNAME_FILE="CNAME"

function log {
  echo "[deploy.sh] $1"
}

log "Adding Philadelphia remote named \"$PHL_REMOTE_NAME..\""

if [[ `git remote | grep $PHL_REMOTE_NAME | wc -l` -eq 0 ]]; then
  git remote add $PHL_REMOTE_NAME $PHL_REMOTE_URL
else
  log "> $PHL_REMOTE_NAME remote already exists"
fi

log "Adding San Diego remote named \"$SAN_REMOTE_NAME..\""

if [[ `git remote | grep $SAN_REMOTE_NAME | wc -l` -eq 0 ]]; then
  git remote add $SAN_REMOTE_NAME $SAN_REMOTE_URL
else
  log "> $SAN_REMOTE_NAME remote already exists"
fi

log "Deploying Philadelphia version..."

if [[ `git br | grep $PHL_BRANCH | wc -l` -eq 0 ]]; then
  git branch $PHL_BRANCH
  git branch -u $PHL_REMOTE_NAME/$GITHUB_PAGES_BRANCH $PHL_BRANCH
fi

git checkout $PHL_BRANCH
if [ $? -ne 0 ]; then
  log "Can't check out $PHL_BRANCH - aborting!"
  exit 1
fi

log "Checking that context is set to phl in _config.yml..."

if [[ `grep -q "^context: *phl *$" _config.yml | wc -l` -eq 0 ]]; then
  log "Context is already set to phl!"
else 
  log "Context is not set to phl. Updating it now..."
  sed -i '' 's/^context:.*$/context: phl/g' _config.yml
  git commit -am "Updating context to phl (via deploy.sh)"
fi

git push $PHL_REMOTE_NAME $PHL_BRANCH:$GITHUB_PAGES_BRANCH

log "Done with Philadelphia version!"


log "Deploying San Diego version..."

if [[ `git br | grep $SAN_BRANCH | wc -l` -eq 0 ]]; then
  git branch $SAN_BRANCH
  git branch -u $SAN_REMOTE_NAME/$GITHUB_PAGES_BRANCH $SAN_BRANCH
fi

log "git checkout $SAN_BRANCH"
git checkout $SAN_BRANCH
if [ $? -ne 0 ]; then
  log "Can't check out $SAN_BRANCH - aborting!"
  exit 1
fi

if [ `cat CNAME` != $SAN_HOST ]; then
  log "Updating CNAME file on $SAN_BRANCH..."
  
  echo $SAN_HOST > $CNAME_FILE
  git add $CNAME_FILE
  git commit -m "Updating CNAME for Long Beach website (via deploy.sh)"

  log "Done updating CNAME file on $SAN_BRANCH"
fi

git merge $PHL_BRANCH -m "Merging $PHL_BRANCH INTO $SAN_BRANCH (via deploy.sh)"
if [ $? -ne 0 ]; then
  log "Couldn't merge $PHL_BRANCH into $SAN_BRANCH - aborting!"
  exit 1
fi

log "Updating context to san in _config.yml..."

sed -i '' 's/^context: *phl *$/context: san/g' _config.yml

if git diff-index --exit-code --quiet HEAD -- config.yml; then
  log "No changes to context needed in _config.yml"
else
  log "Commiting changes made to context in _config.yml"
  git commit -am "Updating context to san (via deploy.sh)"  
fi

log "Done updating context to SAN in _config.yml!"

git push $SAN_REMOTE_NAME $SAN_BRANCH:$GITHUB_PAGES_BRANCH

log "Done with San Diego version!"

log "Checking out $PHL_BRANCH..."
git checkout $PHL_BRANCH


log "Done updating all website versions!!!"