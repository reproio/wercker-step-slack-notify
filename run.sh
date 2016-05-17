#!/bin/bash

#
# Hundle arguments
#
AVATAR="\"icon_url\":\"https://avatars3.githubusercontent.com/u/1695193?s=140\""

if [ ! -n "$SLACK_INCOMMING_WEBHOOK_URL" ]; then
  fail 'Please specify incomming webhook url property'
  exit 1
fi

if [ -n "$SLACK_ICON_EMOJI" ]; then
  AVATAR="\"icon_emoji\":\"$SLACK_ICON_EMOJI\""
fi

if [ -n "$SLACK_ICON_URL" ]; then
  AVATAR="\"icon_url\":\"$SLACK_ICON_URL\""
fi

#
# Build message
#
MESSAGE_OWNER="<https://$WERCKER_GIT_DOMAIN/$WERCKER_GIT_OWNER/$WERCKER_GIT_REPOSITORY|$WERCKER_GIT_OWNER/$WERCKER_GIT_REPOSITORY>:"

if [ ! -n "$DEPLOY" ]; then
  MESSAGE_TARGET="<$WERCKER_BUILD_URL|build> of $WERCKER_GIT_BRANCH"
else
  MESSAGE_TARGET="<$WERCKER_DEPLOY_URL|deploy> of $WERCKER_GIT_BRANCH to $WERCKER_DEPLOYTARGET_NAME"
fi

if [ "$WERCKER_RESULT" = "passed" ]; then
  STATUS="passed"
  COLOR="good"
else
  STATUS="failed"
  COLOR="danger"
fi

MESSAGE="$MESSAGE_OWNER $MESSAGE_TARGET"

#
# Build query
#
QUERY="payload={ \
  \"attachments\":[{ \
    \"fallback\":\"$MESSAGE\", \
    \"color\":\"$COLOR\", \
    \"fields\":[{ \
      \"title\":\"$STATUS\", \
      \"value\":\"$MESSAGE\", \
      \"short\":false \
    }]  \
  }], \
  $AVATAR \
}"

#
# Request notification
#
if [ "$WERCKER_SLACK_NOTIFY_ON" = "failed" ]; then
  if [ "$WERCKER_RESULT" = "passed" ]; then
    echo "Skipping.."
    return 0
  fi
fi

RESPONSE=`curl -X POST --data-urlencode "$QUERY" "$SLACK_INCOMMING_WEBHOOK_URL" -w " %{http_code}" -s`

if [ `echo $RESPONSE | awk '{ print $NF }'` != "200" ]; then
  error "$RESPONSE"
fi
