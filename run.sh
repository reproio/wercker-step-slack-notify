#!/bin/bash

# stab error method
if [ -n "$SLACK_NOTIFY_DEBUG_MODE" ]; then
  function fail() { echo $1; }
  function debug() { echo $1; }
fi

#
# Hundle arguments
#
USERNAME="\"username\":\"wercker\""
AVATAR="\"icon_url\":\"https://avatars3.githubusercontent.com/u/1695193?s=140\""

if [ ! -n "$WERCKER_SLACK_NOTIFY_SUBDOMAIN" ]; then
  fail 'Please specify the subdomain property'
  exit 1
fi

if [ ! -n "$WERCKER_SLACK_NOTIFY_TOKEN" ]; then
  fail 'Please specify token property'
  exit 1
fi

if [ ! -n "$WERCKER_SLACK_NOTIFY_CHANNEL" ]; then
  fail 'Please specify a channel'
  exit 1
fi

if [[ $WERCKER_SLACK_NOTIFY_CHANNEL == \#* ]]; then
  fail "Please specify the channel without the '#'"
  exit 1
fi

if [ -n "$WERCKER_SLACK_NOTIFY_USERNAME" ]; then
  USERNAME="\"username\":\"$WERCKER_SLACK_NOTIFY_USERNAME\""
fi

if [ -n "$WERCKER_SLACK_NOTIFY_ICON_EMOJI" ]; then
  AVATAR="\"icon_emoji\":\"$WERCKER_SLACK_NOTIFY_ICON_EMOJI\""
fi

if [ -n "$WERCKER_SLACK_NOTIFY_ICON_URL" ]; then
  AVATAR="\"icon_url\":\"$WERCKER_SLACK_NOTIFY_ICON_URL\""
fi

#
# Build message
#
MESSAGE_OWNER="<https://$WERCKER_GIT_DOMAIN/$WERCKER_GIT_OWNER/$WERCKER_GIT_REPOSITORY|$WERCKER_GIT_OWNER/$WERCKER_GIT_REPOSITORY>:"
MESSAGE_KICKER="<https://$WERCKER_SLACK_NOTIFY_SUBDOMAIN.slack.com/team/$WERCKER_STARTED_BY|@$WERCKER_STARTED_BY>"

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

MESSAGE="$MESSAGE_OWNER $MESSAGE_TARGET by $MESSAGE_KICKER $STATUS."

#
# Build query
#
QUERY="payload={ \
  \"channel\": \"#$WERCKER_SLACK_NOTIFY_CHANNEL\", \
  $USERNAME, \
  \"username\": \"wercker\", \
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
REQUEST_URL="https://$WERCKER_SLACK_NOTIFY_SUBDOMAIN.slack.com/services/hooks/incoming-webhook?token=$WERCKER_SLACK_NOTIFY_TOKEN"

#
# Request notification
#
if [ "$WERCKER_SLACK_NOTIFY_ON" = "failed" ]; then
  if [ "$WERCKER_RESULT" = "passed" ]; then
    echo "Skipping.."
    return 0
  fi
fi

RESPONSE=`curl -X POST --data-urlencode "$QUERY" "$REQUEST_URL" -w " %{http_code}" -s`

if [ `echo $RESPONSE | awk '{ print $NF }'` != "200" ]; then
  error "$RESPONSE"
fi
