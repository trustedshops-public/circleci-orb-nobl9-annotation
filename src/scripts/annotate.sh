PARAM_NOBL9_CLIENT_ID=$(eval echo "\$$PARAM_NOBL9_CLIENT_ID")
PARAM_NOBL9_CLIENT_SECRET=$(eval echo "\$$PARAM_NOBL9_CLIENT_SECRET")
PARAM_NOBL9_ORGANIZATION=$(eval echo "\$$PARAM_NOBL9_ORGANIZATION")

NOBL9_ACCESS_TOKEN="$(curl --location --request POST 'https://app.nobl9.com/api/accessToken' --user "$PARAM_NOBL9_CLIENT_ID":"$PARAM_NOBL9_CLIENT_SECRET" \
--header 'Organization: '"$PARAM_NOBL9_ORGANIZATION"'' | jq -r '.access_token')"

DEPLOYMENT_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

curl --location --request POST 'https://app.nobl9.com/api/annotations' \
--header 'Authorization: Bearer '"$NOBL9_ACCESS_TOKEN"'' \
--header 'organization: '"$PARAM_NOBL9_ORGANIZATION"'' \
--header 'Content-Type: application/json' \
--data @- <<TEXT
{
    "name": "$PARAM_NOBL9_ANNOTATION_NAME",
    "project": "$PARAM_NOBL9_ANNOTATION_PROJECT",
    "slo": "$PARAM_NOBL9_ANNOTATION_SLO",
    "description": "$PARAM_NOBL9_ANNOTATION_DESCRIPTION",
    "startTime": "$DEPLOYMENT_DATE",
    "endTime": "$DEPLOYMENT_DATE"
}
TEXT
