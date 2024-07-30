#!/bin/bash

# Check if the file exists
if [ ! -f "ansible.inv" ]; then
    echo "Error: ansible.inv file not found."
    exit 1
fi

# Create or truncate routes.txt
> routes.txt

# Read the file line by line
while IFS= read -r line; do
    # Check if the line starts with "[global]"
    if [[ "$line" == "[global]" ]]; then
        echo "Found [global] section."
    else
        # Extract IP address from the line
        ip_address=$(echo "$line" | tr -d '{}')
        # Write formatted output to routes.txt
        echo "\"nats://$ip_address:6222\"" >> routes.txt
    fi
done < "ansible.inv"

# Append routes.txt to an existing nats.conf file and create new_nats.conf
cat nats.conf routes.txt > new_nats.conf

# Add the closing brackets to new_nats.conf
echo "]" >> new_nats.conf
echo "}" >> new_nats.conf

echo "Output written to new_nats.conf"
