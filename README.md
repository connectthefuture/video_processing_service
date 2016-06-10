# Bitfusion Mobile Video Processing Service

This system and API are built on top of ffmpeg, a leading multimedia 
framework capable of manipulating or playing just about anything created.

This system install and API is designed specifically around video modification tasks.
It will take a singular input file, carry out the task on the file, and return a file back.

FFmpeg is compiled with following libraries:
 * Yasm: An assembler for x86 optimizations used by x264 and FFmpeg
 * libx264: H.264 video encoder
 * libx25: H.265/HEVC video encoder
 * libfdk-aac: AAC audo encoder
 * libmp3lame:  MP# audio encoder
 * libopus: Opus audio decoder & encoder
 * libvpx: VP8/VP9 video encoder and decoder
 * nvida sdk 6.0.1: Nvidia video encoder & decoder libraries


## Benchmarks

 * Input File: big_buck_bunny_480p_surround-fix.avi
 * Size: 210MB


| System               | Video Codec | CPU | GPU | Time        |
|----------------------|-------------|-----|-----|-------------|
| AWS g2.2xlarge       | nvenc       | no  | yes | 22s         |    
| AWS g2.2xlarge       | libx264     | yes | no  | 59s         | 
| Local Laptop/vagrant | libx264     | yes | no  | 19m27.484s  |


## API


| METHOD       | URI                                 | ACTION                                             |
|--------------|-------------------------------------|----------------------------------------------------|   
| POST         | http://[hostname]/input/            | Upload a video file                                |  
| GET          | http://[hostname]/input/            | List all uploaded files                            |
| DELETE       | http://[hostname]/input/{file_name} | Delete an uploaded file                            |
| POST         | http://[hostname]/job/              | Submit a ffmpeg job & return a task ID or get info |
| GET          | http://[hostname]/job/{id}          | Get job status based on the returned task ID       |
| GET          | http://[hostname]/output/           | List output files available                        |
| GET          | http://[hostname]/output/file_name  | Download the output file                           |
| DELETE       | http://[hostname]/output/file_name  | delete output file                                 |



## API Token

When the system starts, the API token will be set to the instance-id.  You will need to pass the
header 'X-Auth-Token' and have it set to the instance ID for any of the API calls to function.


## Examples

We have also included example bash scripts in the examples folder. 

To use the examples in the example directory:

 1. Upload a file using "job_upload_avi.sh
 1. Use any of the job_task_* to submit a job and have it return a file.  
    * In the examples you will need to update the Token, EC2 instance, input file & output file

## Example Walkthrough

The steps below will walk you through the process of:

 1. Uploading a video file
 1. Submitting a job
 1. Polling the job status
 1. Retrieving output file

#### Step 1 - Upload a video file

```
#!/usr/bin/env bash

token="{ec2 instance id}"
host_ip="{ec2 public ip address}"
file="big_buck_bunny_720p_stereo.avi"  # Download from: http://download.blender.org/peach/bigbuckbunny_movies/big_buck_bunny_720p_stereo.avi


curl --progres-bar -X POST \
-H "X-Auth-Token: ${token}" \
-H "Cache-Control: no-cache" \
-H "Content-Type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW" \
-F "file=@${file}" \
http://${host_ip}:5000/input/ > /dev/null

# Expected output:
# {
#     "filename": "big_buck_bunny_720p_stereo.avi",
#     "status": "success"
# }

``` 


#### Step 2 - Submit a job. 

```
#!/usr/bin/env bash

token="{ec2 instance id}"
host_ip="{ec2 public ip address}"
input_file="big_buck_bunny_720p_stereo.avi"
output_file="big_buck_bunny_720p_stereo_libx264.avi"
cmd_args="-vcodec libx264 -b:v 5M -acodec copy"

curl --silent -X POST \
  -H "X-Auth-Token: ${token}" \
  -H "Cache-Control: no-cache" \
  -H "Content-Type: application/json" \
  -d '{ "input_file": "'${input_file}'", "output_file": "'${output_file}'", "cmd_args": "'"${cmd_args}"'" }' \
  http://${host_ip}:5000/job/


# Expected output:
# {
#   "input_file": "big_buck_bunny_720p_stereo.avi",
#   "messege": "Job submitted",
#   "status": "suceeded",
#   "task_id": "890e7930-ab3c-4cfd-a51b-2c1c52b1c11d",
# }
```
 
  
#### Step 3 - Use the task ID to get the status of the job.
  * Returns the following:
    * state: failed, pending, success
    * If the job succeeded it returns information about the job:
      * cmd: command used
      * cmd_err: Any output directed to stderr
      * cmd_output:  This is the stand blender job output
      * cmd_return_code:  The return code of the command.  0 means it completed successfully
      * output_file: This will be the output file with the task id appended
      * state:  This is state of the worker job.

```
#!/usr/bin/env bash

token="{ec2 instance id}"
host_ip="{ec2 public ip address}"
job_id="8c994d30-5e65-495f-8589-a63f541b1161"

curl -X GET \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: ${token}" \
  -H "Cache-Control: no-cache" \
  "http://${host_ip}:5000/job/${job_id}"


# Expected output when the job is running:

# {
#     "status": "pending"
# }

# Expected output when the job completes:

# {
#     "result": {
#         "cmd": "...."
#     "cmd_return_code": 0,
#     "output_file": "big_buck_bunny_720p_.avi",
#     "task_id": "890e7930-ab3c-4cfd-a51b-2c1c52b1c11d",
#   },
#   "state": "SUCCESS"
# }
```

#### Step 4 - Request the output_file returned to you in step 3

```
#!/usr/bin/env bash

token="<replace with ec2 instance_id>"
host_ip="5host_ip="<replace with ec2 public ip address>"
output_file="big_buck_bunny_720p_stereo_libx264.avi"

curl -O -X GET \
 -H "Content-Type: application/json" \
 -H "X-Auth-Token: ${token}" \
 -H "Cache-Control: no-cache" \
 "http://52.87.180.179:5000/output/${output_file}"

# Expected output
# The file will be saved locally
```


## Tested Commands

We used the following ffmpeg commands to test the API

### Convert an avi file into mpg format

 * Example script: [job_task_avi_to_mpg.sh](examples/job_task_avi_to_mpg.sh)

```
ffmpeg -y -i big_buck_bunny_480p_surround-fix.avi big_buck_bunny_480p_surround-fix.mpg
```


### Convert and maintain quality

 * Example script: [job_task_qscale.sh](examples/job_task_qscale.sh)

```
ffmpeg -y -i big_buck_bunny_480p_surround-fix.avi -qscale 0 big_buck_bunny_480p_surround-fix.mpg
```

### Set the Bitrate to 128K

 * Example script: [job_task_bitrate_128k.sh](examples/job_task_bitrate_128k.sh)

```
ffmpeg -y -i big_buck_bunny_480p_surround-fix.avi -b 128k big_buck_bunny_480p_surround-fix-128.avi
```

### Transcode with libx264

 * Example script: [job_task_avi_to_mp4_libx264.sh](examples/job_task_avi_to_mp4_libx264.sh)

```
ffmpeg -y -i big_buck_bunny_480p_surround-fix.avi -vcodec libx264 -b:v 5M -acodec copy big_buck_bunny_720p_stereo-libx264.mp4
```

### Extract a Single Frame

 * Example script: [job_task_avi_extract_single_frame.sh](examples/job_task_avi_extract_single_frame.sh)

```
ffmpeg -y -i big_buck_bunny_480p_surround-fix.avi -ss 60 -t 1 -s 480x300 -f image2 big_buck_bunny_frame.jpg
```

### Transcode with nvidia GPU

 * Example script: [job_task_avi_to_mp4_nvenc.sh](examples/job_task_avi_to_mp4_nvenc.sh)

```
ffmpeg -y -i big_buck_bunny_480p_surround-fix.avi -vcodec nvenc -b:v 5M -acodec copy big_buck_bunny_480p_surround-fix-nvenc.mp4
```
