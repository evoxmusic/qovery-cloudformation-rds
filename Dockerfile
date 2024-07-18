FROM alpine:3.20.0

  # downloading dependencies and initializing working dir
RUN <<EOF
set -e
apk update
apk add dumb-init
apk add 'aws-cli>2.16' --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community
apk add jq
adduser -D app
mkdir /data
chown -R app:app /data
EOF

WORKDIR /data
USER app

# Create the Python script to transform the output keys from CamelCase
# to UPPER_CASE_WITH_UNDERSCORES in the Qovery format
RUN cat <<EOF > transform_output.py
import json
import re
import sys

# Function to convert CamelCase to UPPER_CASE_WITH_UNDERSCORES
def camel_to_upper_snake(name):
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    s2 = re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1)
    return s2.upper()

def transform(input_file, output_file):
    # Read the JSON data from file
    with open(input_file, 'r') as infile:
        data = json.load(infile)

    # Transform the keys
    transformed_data = {}
    for item in data:
        key = camel_to_upper_snake(item['OutputKey'])
        transformed_data[key] = {
            'value': item['OutputValue'],
            'type': 'string',
            'sensitive': True
        }

    # Write the transformed data to a new file
    with open(output_file, 'w') as outfile:
        json.dump(transformed_data, outfile, indent=2)

    print(f"Transformation complete. Check {output_file} for the result.")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python transform_output.py <input_file> <output_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    transform(input_file, output_file)
EOF

RUN chmod +x transform_output.py

# Create the entrypoint script with the commands to be run on the environment:
# - start --> run "cloudformation deploy" + use "cloudformation describe-stacks" to generate the output to be fetched by Qovery and injected later as an environment variable for the other services within the same environment
# - stop --> nothing
# - delete --> run "cloudformation delete-stack"
# other commands are available and can be customized in this Dockerfile
# the stack name is created based on the QOVERY_JOB_ID environment variable

RUN cat <<EOF > entrypoint.sh
#!/bin/sh

# if job input is a JSON and is not empty, then we can save it into a file input.json
if [ "\$JOB_INPUT_JSON" != '' ];
then
  echo "\$JOB_INPUT_JSON" > /data/input.json
  PARAMETERS="file:///data/input.json"
fi

CMD=\$1; shift
set -ex

cd cloudformation

STACK_NAME="qovery-stack-\${QOVERY_JOB_ID%%-*}"

case "\$CMD" in
start)
  echo 'start command invoked'

  # Temporarily disable exit on error
  set +e
  # Check if the stack exists
  STACK_EXISTS=\$(aws cloudformation describe-stacks --stack-name \$STACK_NAME 2>&1)
  # Re-enable exit on error
  set -e

  if echo "\$STACK_EXISTS" | grep -q "does not exist"; then
    echo 'Stack does not exist. Creating a new stack...'
    echo 'Creating stack with the following parameters:'
    echo 'STACK_NAME: '\$STACK_NAME
    echo 'CF_TEMPLATE_PATH: '\$CF_TEMPLATE_PATH
    echo 'PARAMETERS: '\$PARAMETERS

    aws cloudformation create-stack --stack-name \$STACK_NAME --template-body file:///data/\$CF_TEMPLATE_PATH --parameters \$PARAMETERS
    # Wait until the stack creation is complete
    aws cloudformation wait stack-create-complete --stack-name \$STACK_NAME
  else
    echo 'Stack exists. Updating the stack...'
    echo 'Updating stack with the following parameters:'
    echo 'STACK_NAME: '\$STACK_NAME
    echo 'CF_TEMPLATE_PATH: '\$CF_TEMPLATE_PATH
    echo 'PARAMETERS: '\$PARAMETERS

    # Temporarily disable exit on error
    set +e
    UPDATE_OUTPUT=\$(aws cloudformation update-stack --stack-name \$STACK_NAME --template-body file:///data/\$CF_TEMPLATE_PATH --parameters \$PARAMETERS 2>&1)
    # Re-enable exit on error
    set -e

    if echo "\$UPDATE_OUTPUT" | grep -q "No updates are to be performed"; then
      echo 'No updates are to be performed. Skipping...'
    else
      echo 'Update stack failed with error:'
      echo "\$UPDATE_OUTPUT"
      exit 1
    fi

    # Wait until the stack update is complete
    aws cloudformation wait stack-update-complete --stack-name \$STACK_NAME
  fi

  echo 'Generating stack output - injecting it as Qovery environment variable for downstream usage'
  aws cloudformation describe-stacks --stack-name \$STACK_NAME --output json --query "Stacks[0].Outputs" > /data/output.json
  ehco 'Transforming the output keys to UPPER_CASE_WITH_UNDERSCORES in the Qovery format'
  python transform_output.py /data/output.json /qovery-output/qovery-output.json
  ;;

stop)
  echo 'stop command invoked'
  exit 0
  ;;

delete)
  echo 'delete command invoked'
  aws cloudformation delete-stack --stack-name \$STACK_NAME
  aws cloudformation wait stack-delete-complete --stack-name \$STACK_NAME
  ;;

raw)
  echo 'raw command invoked'
  aws cloudformation "\$1" "\$2" "\$3" "\$4" "\$5" "\$6" "\$7" "\$8" "\$9"
  ;;

debug)
  echo 'debug command invoked. sleeping for 9999999sec'
  echo 'Use remote shell to connect and execute commands'
  sleep 9999999999
  exit 1
  ;;

*)
  echo "Command not handled by entrypoint.sh: '\$CMD'"
  exit 1
  ;;
esac

EOF

COPY --chown=app:app . cloudformation

RUN <<EOF
set -e
chmod +x entrypoint.sh
cd cloudformation
EOF

# These env vars shall be set as environment variables within the Qovery console
ENV CF_TEMPLATE_NAME=must-be-set-as-env-var
ENV AWS_DEFAULT_REGION=must-be-set-as-env-var
ENV AWS_SECRET_ACCESS_KEY=must-be-set-as-env-var
ENV AWS_ACCESS_KEY_ID=must-be-set-as-env-var


ENTRYPOINT ["/usr/bin/dumb-init", "-v", "--", "/data/entrypoint.sh"]
CMD ["start"]