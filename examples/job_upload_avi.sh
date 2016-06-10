#!/usr/bin/env bash
token="i-53df5ccf"
host_ip="52.87.192.160"
input_file="big_buck_bunny_480p_surround-fix.avi"

###############################################################################
# FUNCTIONS
###############################################################################

function upload_blend_file() {

    curl -X POST \
      -H "X-Auth-Token: ${token}" \
      -H "Cache-Control: no-cache" \
      -H "Content-Type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW" \
      -F "file=@${input_file}" \
      http://${host_ip}:5000/input/

}

###############################################################################
# MAIN
###############################################################################
input_file=$( basename ${input_file} )

echo ""
echo "Uploading File: ${input_file}"
upload_blend_file