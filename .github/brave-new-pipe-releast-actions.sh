#!/usr/bin/env bash

set -e

if [[ $# -ne 2 ]]; then
  echo "This needs a release tag. and a apk file:"
  echo "e.g. $0 v0.0.1 BraveNewPipe.apk"
  exit 1
fi

if [[ -z "$GITHUB_SUPER_TOKEN" ]]; then
  echo "This script needs a GitHub personal access token."
  exit 1
fi
BNP_R_MGR_REPO="bnp-r-mgr"
TAG=$1
APK_FILE=$2
GITHUB_LOGIN="evermind-zz"
RELEASE_BODY="Apk available at bravenewpipe/NewPipe@${TAG}](https://github.com/bravenewpipe/NewPipe/releases/tag/${TAG})."

PRERELEASE="false"
if [[ "$TAG" == "latest" ]]; then
  PRERELEASE="true"
fi

#if [[ "$GITHUB_REPOSITORY" != "evermind-zz/actions" ]]; then
#  echo "This mirror script is only meant to be run from evermind-zz/actions, not ${GITHUB_REPOSITORY}. Nothing to do here."
#  exit 0
#fi

create_tagged_release() {
  REPO=$1
  COMMIT_MSG=$2
  pushd /tmp/${REPO}/

  # Set the local git identity
  git config user.email "${GITHUB_LOGIN}@users.noreply.github.com"
  git config user.name "$GITHUB_LOGIN"
date

  # Obtain the release ID for the previous release of $TAG (if present)
  local previous_release_id=$(curl --user ${GITHUB_LOGIN}:${GITHUB_SUPER_TOKEN} --request GET --silent https://api.github.com/repos/${GITHUB_LOGIN}/${REPO}/releases/tags/${TAG} | jq '.id')

  # Delete the previous release (if present)
  if [[ -n "$previous_release_id" ]]; then
    echo "Deleting previous release: ${previous_release_id}"
    curl \
      --user ${GITHUB_LOGIN}:${GITHUB_SUPER_TOKEN} \
      --request DELETE \
      --silent \
      https://api.github.com/repos/${GITHUB_LOGIN}/${REPO}/releases/${previous_release_id}
  fi
date

  # Delete previous identical tags, if present
  git tag -d $TAG || true
  git push origin :$TAG || true

  # Add all the changed files and push the changes upstream
  git add -f .
  git commit -m "${COMMIT_MSG}" || true
  git push -f origin master:master
  git tag $TAG
  git push origin $TAG
date

# evermind -- we don't want any release entries there  # Generate a skeleton release on GitHub
# evermind -- we don't want any release entries there  curl \
# evermind -- we don't want any release entries there    --user ${GITHUB_LOGIN}:${GITHUB_SUPER_TOKEN} \
# evermind -- we don't want any release entries there    --request POST \
# evermind -- we don't want any release entries there    --silent \
# evermind -- we don't want any release entries there    --data @- \
# evermind -- we don't want any release entries there    https://api.github.com/repos/${GITHUB_LOGIN}/${REPO}/releases <<END
# evermind -- we don't want any release entries there  {
# evermind -- we don't want any release entries there    "tag_name": "$TAG",
# evermind -- we don't want any release entries there    "name": "Auto-generated release for tag $TAG",
# evermind -- we don't want any release entries there    "body": "$RELEASE_BODY",
# evermind -- we don't want any release entries there    "draft": false,
# evermind -- we don't want any release entries there    "prerelease": $PRERELEASE
# evermind -- we don't want any release entries there  }
# evermind -- we don't want any release entries thereEND
  popd
}

URL="https://github.com/bravenewpipe/NewPipe/releases/download/${TAG}/BraveNewPipe_${TAG}.apk"
VERSION_NAME=${TAG/v/} 
date

BUILD_TOOLS_VERSION="${BUILD_TOOLS_VERSION:-29.0.3}"
AAPT=$ANDROID_HOME/build-tools/$BUILD_TOOLS_VERSION/aapt

VERSION_CODE="$($AAPT d badging $APK_FILE | grep -Po "(?<=\sversionCode=')([0-9.-]+)")"
date
TEMPFILE="$(mktemp  -p $PWD -t sdflhXXXXXXXXX)"
JSON_FILE=data.json

# updating json release
rm -rf "/tmp/${BNP_R_MGR_REPO}"
git clone "https://evermind-zz:${GITHUB_SUPER_TOKEN}@github.com/evermind-zz/${BNP_R_MGR_REPO}.git" /tmp/${BNP_R_MGR_REPO}
# update the json file
date
cat /tmp/${BNP_R_MGR_REPO}/api/$JSON_FILE \
    | jq '.flavors.github.stable.version_code = '${VERSION_CODE}'' \
    | jq '.flavors.github.stable.version = "'${VERSION_NAME}'"' \
    | jq '.flavors.github.stable.apk = "'${URL}'"' \
    > $TEMPFILE
date

mv $TEMPFILE /tmp/${BNP_R_MGR_REPO}/api/$JSON_FILE
date
create_tagged_release "$BNP_R_MGR_REPO" "\"version\": \"$VERSION_NAME\""
date

