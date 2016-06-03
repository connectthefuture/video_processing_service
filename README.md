# Bitfusion Video Transcoding Service

This system currently is designe specifically around videos modification tasks.  As an input file it will take one video file carry out the task and return the Video back.

* CPU & GPU enabled
** Benefits from a GPU, but only uses a single GPU core.  So best to use with a g2.2xlarge
* Cuda 7.5
* Nvidia Driver 352
* wget http://developer.download.nvidia.com/compute/nvenc/v5.0/nvenc_5.0.1_sdk.zip -O sdk.zip
** unzip sdk.zip

## Bitfusion FFMPEG API


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
header 'X-Auth-Token' and have it set to the instance ID for any of the calls to function.

Key Tasks
* List video information
* Convert video format

### Example:

ENCODE A VIDEO SEQUENCE FOR THE IPPOD/IPHONE

```
ffmpeg -i source_video.avi input -acodec aac -ab 128kb -vcodec mpeg4 -b 1200kb -mbd 2 -flags +4mv+trell -aic 2 -cmp 2 -subcmp 2 -s 320x180 -title X final_video.mp4
```


#### Walkthrough of how to submit a job:

Below will walk you through the process of uploading a video file, submitting a job, then retrieving it.  We have also included an example script that will go through the entire process described below. 

 * https://github.com/bitfusionio/..../blob/master/example.sh

#### Step 1 - Upload Video file

```
#!/usr/bin/env bash

token="<replace with ec2 instance_id>"
host_ip="<replace with ec2 public ip address"
file="big_buck_bunny_720p_stereo.avi"  # Download from: http://download.blender.org/peach/bigbuckbunny_movies/big_buck_bunny_720p_stereo.avi


curl -X POST \
-H "X-Auth-Token: ${token}" \
-H "Cache-Control: no-cache" \
-H "Content-Type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW" \
-F "file=@${file}" \
http://${host_ip}:5000/input/

# Expected output:
# {
#     "filename": "big_buck_bunny_720p_stereo.avi",
#     "status": "success"
# }

``` 


#### Step 2 - Submit a job. 
  * When you submit a job we append our arguments file to force GPU or CPU processing based on the system.  What this means is that we if you are running on a g2.2xlarge or a g2.8xlarge we will enable GPU processing.
    * Job with the following parameters: 
    * input_file (e.g. BMW27.blend)
    * zip_file (e.g. BMW27.blend.zip)
    * blender_args (e.g -f 1).
  * We return the generated task ID for future lookup
```
#!/usr/bin/env bash

token="<replace with ec2 instance_id>"
host_ip="5host_ip="<replace with ec2 public ip address>"
file="big_buck_bunny_720p_stereo.avi"
ffmpeg_args="-vcodec libx264 -b:v 5M -acodec copy"

curl -X POST \
  -H "X-Auth-Token: ${token}" \
  -H "Cache-Control: no-cache" \
  -H "Content-Type: application/json" \
  -d "input_file": "'${file}'", "ffmpeg_args": "'${ffmpeg_args}'" }' \
  http://${host_ip}:5000/job/


# Expected output:
# {
#   "input_file": "BMW27.blend",
#   "messege": "Job submitted",
#   "status": "suceeded",
#   "task_id": "890e7930-ab3c-4cfd-a51b-2c1c52b1c11d",
#   "file": "big_buck_bunny_720p_stereo.avi"
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
      * zip_info:  This will have information about the zip file upaloded
      * state:  This is state of the worker job.

```
#!/usr/bin/env bash

token="<replace with ec2 instance_id>"
host_ip="5host_ip="<replace with ec2 public ip address>"
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
#     "output_file": "big_buck_bunny_720p_stereo-890e7930-ab3c-4cfd-a51b-2c1c52b1c11d-01.avi",
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
output_file="BMW27-890e7930-ab3c-4cfd-a51b-2c1c52b1c11d-01.png"

curl -O -X GET \
 -H "Content-Type: application/json" \
 -H "X-Auth-Token: ${token}" \
 -H "Cache-Control: no-cache" \
 "http://52.87.180.179:5000/output/${output_file}"

# Expected output
# The rendered file will be saved locally
```
