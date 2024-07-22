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

hdp run -r helpers/target/bs_request.json -p helpers/target/bs_cached_input.json -o helpers/target/bs_cached_output.json -c helpers/target/bs_hdp_pie.zip
hdp run -r helpers/target/tx_request.json -p helpers/target/tx_cached_input.json -o helpers/target/tx_cached_output.json -c helpers/target/tx_hdp_pie.zip
# hdp run-module 0x4F21E5,0x4F21E8,0x13cb6ae34a13a0977f4d7101ebc24b87bb23f0d5 --class-hash 0x00ababb33ae5911fd14e6b9f2853b6271f553b9ec7835298134f4bb020100971 -p helpers/target/md_cached_input.json -o helpers/target/md_cached_output.json -c helpers/target/md_hdp_pie.zip