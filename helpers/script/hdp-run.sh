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

hdp encode -a -p helpers/target/bs_cached_input.json -o helpers/target/bs_cached_output.json -c helpers/target/bs_hdp_pie.zip slr none.10000000 -b 5858987 5858997 header.excess_blob_gas 2
hdp encode -a -p helpers/target/tx_cached_input.json -o helpers/target/tx_cached_output.json -c helpers/target/tx_hdp_pie.zip slr none.50 -t 5605816 tx_receipt.success 12 53 1 0,0,1,1
hdp run-module 0x4F21E5,0x4F21E8,0x13cb6ae34a13a0977f4d7101ebc24b87bb23f0d5 --class-hash 0x02aacf92216d1ae71fbdaf3f41865c08f32317b37be18d8c136d442e94cdd823 -p helpers/target/md_cached_input.json -o helpers/target/md_cached_output.json -c helpers/target/md_hdp_pie.zip