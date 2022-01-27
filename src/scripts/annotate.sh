#!/bin/bash

BASIC_TOKEN="$( echo "$PARAM_NOBL9_CLIENT_ID":"$PARAM_NOBL9_CLIENT_SECRET" | base64 -w0)"

NOBL9_ACCESS_TOKEN="$(curl --location --request POST 'https://app.nobl9.com/api/accessToken' \
--header 'Organization: '"$PARAM_NOBL9_ORGANIZATION"'' \
--header 'Authorization: Basic '"$BASIC_TOKEN"'' | jq -r '.access_token')"

DEPLOYMENT_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

curl --location --request POST 'https://app.nobl9.com/api/annotations' \
--header 'Authorization: Bearer '"$NOBL9_ACCESS_TOKEN"'' \
--header 'organization: '"$PARAM_NOBL9_ORGANIZATION"'' \
--header 'Content-Type: application/json' \
--data-raw <<TEXT
{
    "name": "$PARAM_NOBL9_ANNOTATION_NAME",
    "project": "$PARAM_NOBL9_ANNOTATION_PROJECT",
    "slo": "$PARAM_NOBL9_ANNOTATION_SLO",
    "description": "$PARAM_NOBL9_ANNOTATION_DESCRIPTION",
    "startTime": "$DEPLOYMENT_DATE",
    "endTime": "$DEPLOYMENT_DATE"
}
TEXT
