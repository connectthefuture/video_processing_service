#!/usr/bin/env bash

###############################################################################
# Description: Transcode using libx264
###############################################################################


###############################################################################
# CONFIG
###############################################################################

token="i-8d3fbb11"
host_ip="52.91.46.165"
input_file="big_buck_bunny_480p_surround-fix.avi"
output_file="big_buck_bunny_480p_surround-fix-lbx264.mp4"
cmd_args='-vcodec libx264 -b:v 5M -acodec copy'

###############################################################################
# FUNCTIONS
###############################################################################

function submit_blender_job() {

    local input_file=$1
    local output_file=$2
    local cmd_args=$3

    curl --silent -X POST \
      -H "X-Auth-Token: ${token}" \
      -H "Cache-Control: no-cache" \
      -H "Content-Type: application/json" \
      -d '{ "input_file": "'${input_file}'", "output_file": "'${output_file}'", "cmd_args": "'"${cmd_args}"'" }' \
      http://${host_ip}:5000/job/

}

function get_job_status() {

    local job_id=$1
    curl --silent -X GET \
      -H "Content-Type: application/json" \
      -H "X-Auth-Token: ${token}" \
      -H "Cache-Control: no-cache" \
      "http://${host_ip}:5000/job/${job_id}"
}

function get_rendered_file() {

    local output_file=$1

    curl -O -X GET \
     -H "Content-Type: application/json" \
     -H "X-Auth-Token: ${token}" \
     -H "Cache-Control: no-cache" \
     "http://{$host_ip}:5000/output/${output_file}"


}

###############################################################################
# MAIN
###############################################################################
input_file=$( basename ${input_file} )

sleep 1

echo ""
echo "Submitting Job"
json_output=$( submit_blender_job ${input_file} ${output_file} "${cmd_args}" )
echo $json_output | jq .
job_id=$(echo ${json_output} | jq -r .task_id)

sleep 1

echo ""
echo "Job Status"
count=0
while true; do
    json_output=$(get_job_status ${job_id})
    state=$(echo ${json_output} | jq -r .state)
    return_code=$(echo ${json_output} | jq -r .result.cmd_return_code)

    if [ "${state}" == "PENDING" ]; then
 	    if [ "${count}" == 0 ]; then
        echo "State: Running"
	     else
		    printf '.'
	    fi
      sleep 1
	    (( count++ ))

    elif [ "${state}" == "SUCCESS" ] && [ ${return_code} -eq 0 ]; then
	     echo ""
        echo "State: ${state}"
        rendered_file=$(echo ${json_output} | jq -r .result.output_file )
	      printf '\n%s %d\n' "Render Time(s):" "$count"
        break

    elif [ ${return_code} -ne 0 ]; then
        echo ""
        echo "The FFmpeg task failed"
        echo "Return output:" ${json_output}
        exit 1
    fi
done


echo ""
echo "Downloading Output:"
echo "  Output File: ${rendered_file}"
get_rendered_file $rendered_file

echo ""
echo "Finished"
