#!/bin/bash

# Ensure the script is called with a --user argument
if [ "$#" -ne 1 ] || ! [[ $1 =~ ^--userid= ]]; then
    echo "Usage: $0 --userid=username used early in workshop during terraform setup"
    exit 1
fi

# Extract the username from the --user argument
userid="${1#--userid=}"

LNINPUTFILE="linodejson"
tag="${userid}"
LNOUTPATH="./linode-targets/*"
LNOUT="./linode-targets/"
LNPROC="./linode-processed/"
LNPROCPATH="./linode-processed/*"
mkdir -p $LNOUT
mkdir -p $LNPROC
rm -f $LNOUTPATH
rm -f $LNPROCPATH
rm -f $LNINPUTFILE
# run linode-cli 

linode-cli linodes list --tags=$tag --json > $LNINPUTFILE 

# Read the JSON and process each object
jq -c '.[]' $LNINPUTFILE | while IFS= read -r obj; do
    # Extract the region and ipv4 values
    region=$(echo "$obj" | jq -r '.region')
    ipv4=$(echo "$obj" | jq -r '.ipv4 | map(select(test("^(?!192\\.168)\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$"))) | join(",")')

    # Append ipv4 values to the region file
    echo "$ipv4" >> "$LNOUT${region}"
done

# Format the files in GTM friendly format 
for file in $LNOUTPATH; do
        # Format the IP addresses and overwrite the file
        filename=$(basename "$file")
        cat $file | sed -e 's/^/"/' | sed -e 's/$/",/' | sed -e '1s/^/[/;$s/,$/]/' | tr -d '\n' > $LNPROC/$filename
done

# Build a GTM Property file based on entries 
output_file="${userid}.tf"

cat > "$output_file" <<EOF
resource "akamai_gtm_property" "${userid}" {
  domain                      = akamai_gtm_domain.domain.name
  name                        = "${userid}"
  type                        = "performance"
  ipv6                        = false
  score_aggregation_type      = "worst"
  stickiness_bonus_percentage = 0
  stickiness_bonus_constant   = 0
  use_computed_targets        = false
  balance_by_download_score   = false
  dynamic_ttl                 = 30
  handout_limit               = 0
  handout_mode                = "normal"
  failover_delay              = 0
  failback_delay              = 0
  load_imbalance_percentage   = 1200
  ghost_demand_reporting      = false

  liveness_test {
    name                             = "TCP"
    peer_certificate_verification    = false
    test_interval                    = 10
    test_object                      = ""
    http_error3xx                    = true
    http_error4xx                    = true
    http_error5xx                    = true
    disabled                         = false
    test_object_protocol             = "TCP"
    test_object_port                 = 443
    disable_nonstandard_port_warning = false
    test_timeout                     = 10
    answers_required                 = false
    recursion_requested              = false
  }

EOF

for f in $LNPROCPATH; do
echo "processing $f file"
TARGETS=$(cat "$f")
REGION=$(basename "$f")
cat >> "$output_file" <<EOF
  traffic_target {
    datacenter_id = akamai_gtm_datacenter.$REGION.datacenter_id
    enabled       = true
    weight        = 0
    servers       = $TARGETS
  }
EOF
done

echo "}" >> "$output_file"
