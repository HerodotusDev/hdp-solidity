#!/bin/bash

prepare_cairo_enviroment() {
    # Activate the virtual environment
    source ./venv/bin/activate 
    # Check if cairo-run is installed
    cairo-run --version
    local status=$?
        if [ $status -eq 0 ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Successfully prepared"
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed to prepared"
            return $status
        fi
}
# Call the function to ensure the virtual environment is activated
prepare_cairo_enviroment

hdp run -r helpers/target/bs_request.json -p helpers/target/bs_cached_input.json -b helpers/target/bs_cached_output.json -c helpers/target/bs_hdp_pie.zip
hdp run -r helpers/target/tx_request.json -p helpers/target/tx_cached_input.json -b helpers/target/tx_cached_output.json -c helpers/target/tx_hdp_pie.zip
hdp run -r helpers/target/md_request.json -p helpers/target/md_cached_input.json -b helpers/target/md_cached_output.json -c helpers/target/md_hdp_pie.zip