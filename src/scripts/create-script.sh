echo "Create file at ${PARAM_NOBL9_SCRIPT_PATH} ..."

cat <<TEXT > /tmp/create-nobl9-annotation.py
#!/usr/bin/env python3
import urllib.request
import urllib.error
import os
import sys
import json
import base64
from argparse import ArgumentParser
import datetime

# Ansi constants
ANSI_RED = '\u001b[31;1m'
ANSI_RESET = '\u001b[0m'
ANSI_BLUE = '\u001b[34;1m'


def print_err(msg):
    print(f"{ANSI_RED}ERROR: {msg}{ANSI_RESET}")


def print_info_pair(key, value):
    print(f"{ANSI_BLUE}{key.ljust(20)} {ANSI_RESET} {value}")


def parse_cli():
    parser = ArgumentParser(description="Create Nobl9 SLO annotation")
    parser.add_argument("--client-id-var", required=True,
                        help="Name of the environment variable containing the Nobl9 Client ID for the API auth")
    parser.add_argument("--client-secret-var",  required=True,
                        help="Name of the environment variable containing the Nobl9 Client Secret for the API auth")
    parser.add_argument("--organization-var",  required=True,
                        help="Name of the environment variable containing the value for the organization header of the Nobl9 API.")
    parser.add_argument("--annotation-name",  required=False,
                        help="Name of the annotation in Nobl9. Default value is 'circleci-deployment-<workflow-id>-<build_number>'")
    parser.add_argument("--annotation-project",  required=True,
                        help="Name of the project containing the SLO for which the annotation should be created.")
    parser.add_argument("--annotation-slo",  required=True,
                        help="Name of the SLO for which the annotation should be created.")
    parser.add_argument("--annotation-description",  required=False,
                        help="Description of the annotation in Nobl9. Default value is 'CirclecCI Deployment $CIRCLE_BUILD_NUM | Git-SHA1: $CIRCLE_SHA1 | $CIRCLE_BUILD_URL'")
    return parser.parse_args()


def get_access_token(client_id, client_secret, organization):
    url = "https://app.nobl9.com/api/accessToken"

    base64string = base64.b64encode(
        (client_id + ":" + client_secret).encode("ascii"))

    req = urllib.request.Request(url)
    req.add_header("Content-Type", "application/json")
    req.add_header("Authorization", 'Basic {}'.format(
        base64string.decode("ascii")))
    req.add_header("Organization", organization)

    try:
        print("Getting Access Token")
        res = urllib.request.urlopen(req, json.dumps({}).encode("utf8"))
        raw_response = res.read()
        parsed_response = json.loads(raw_response)
        return parsed_response['access_token']
    except urllib.error.HTTPError as e:
        print_err("Failed to get access token from Nobl9 API")
        print_info_pair("URL", req.full_url)
        print_info_pair("Status", e.code)
        print_info_pair("Response", e.read().decode('utf8'))
        sys.exit(1)
    except urllib.error.URLError as e:
        print_err("Failed to call Nobl9 API")
        print_info_pair("Reason", e.reason)
        sys.exit(2)
    except json.JSONDecodeError as e:
        print_err("Failed to parse json from Nobl9 API - access token")
        print_info_pair("Message", str(e))
        sys.exit(1)


def create_annotation(access_token, payload):
    url = "https://app.nobl9.com/api/annotations"

    req = urllib.request.Request(url)
    req.add_header("Content-Type", "application/json")
    req.add_header("Authorization", 'Bearer {}'.format(access_token))
    req.add_header("Organization", organization)

    try:
        print("Adding Nobl9 SLO annotation")
        res = urllib.request.urlopen(req, json.dumps(payload).encode("utf8"))
        raw_response = res.read()
        parsed_response = json.loads(raw_response)
        print("Annotation response: ", parsed_response)
    except urllib.error.HTTPError as e:
        print_err("Failed add Nobl9 annotation")
        print_info_pair("URL", req.full_url)
        print_info_pair("Status", e.code)
        print_info_pair("Response", e.read().decode('utf8'))
        sys.exit(1)
    except urllib.error.URLError as e:
        print_err("Failed to call Nobl9 API")
        print_info_pair("Reason", e.reason)
        sys.exit(2)
    except json.JSONDecodeError as e:
        print_err("Failed to parse json from Nobl9 API - annotation")
        print_info_pair("Message", str(e))
        sys.exit(1)


if __name__ == "__main__":
    args = parse_cli()

    client_id = os.environ[args.client_id_var]
    client_secret = os.environ[args.client_secret_var]
    organization = os.environ[args.organization_var]

    access_token = get_access_token(client_id, client_secret, organization)

    # Annotation name
    annotation_name = f"circleci-deployment-{os.environ['CIRCLE_WORKFLOW_ID']}-{os.environ['CIRCLE_BUILD_NUM']}"
    if args.annotation_name is not None:
        annotation_name = args.annotation_name

    # Annotation description
    annotation_description = f"CirclecCI Deployment {os.environ['CIRCLE_BUILD_NUM']}\nGit-SHA1: {os.environ['CIRCLE_SHA1']}\n {os.environ['CIRCLE_BUILD_URL']}"
    if args.annotation_description is not None:
        annotation_description = args.annotation_description

    # Deployment date
    deployment_date = datetime.datetime.now(datetime.timezone.utc).isoformat()

    payload = {
        "name": annotation_name,
        "project": args.annotation_project,
        "slo": args.annotation_slo,
        "description": annotation_description,
        "startTime": deployment_date,
        "endTime": deployment_date
    }

    create_annotation(access_token, payload)

TEXT

sudo mv /tmp/create-nobl9-annotation.py "${PARAM_NOBL9_SCRIPT_PATH}"

echo "Making file ${PARAM_NOBL9_SCRIPT_PATH} executable ..."
sudo chmod +x "${PARAM_NOBL9_SCRIPT_PATH}"
