# Bitfusion Video Transcoding Service

This system install and API is designed specifically around videos modification tasks.  It will take a singular input file, carry out the task on the file, and return a file back.

* CPU & GPU enabled
** This system is compiled GPU support.  In it current state can use only a single GPU core.  So it is best to use it with a g2.2xlarge.
* Cuda 7.5
* Nvidia Driver 358

## Benchmarks

Input File: big_buck_bunny_480p_surround-fix.avi

Command:
```
ffmpeg -y -i big_buck_bunny_480p_surround-fix.avi -vcodec libx264 -b:v 5M -acodec copy big_buck_bunny_720p_stereo.mp4
```

| System                | Time        |
|-----------------------|-------------|
| Mac Laptop/vagrant    | 19m27.484s  |


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


## Tested Commands

### Convert an avi file into mpg format
```
ffmpeg -i big_buck_bunny_480p_surround-fix.avi big_buck_bunny_480p_surround-fix.mpg
```
## Convert and maintain quality
```
ffmpeg -i big_buck_bunny_480p_surround-fix.avi -qscale 0 big_buck_bunny_480p_surround-fix.mpg
```
## Set the Bitrate to 128K
```
ffmpeg -i big_buck_bunny_480p_surround-fix.avi -b 128k big_buck_bunny_480p_surround-fix-128.avi
```
## Transcode with libx264
```
ffmpeg -y -i big_buck_bunny_480p_surround-fix.avi -vcodec libx264 -b:v 5M -acodec copy big_buck_bunny_720p_stereo-libx264.mp4
```

## Extract a Single Frame
```
ffmpeg -i big_buck_bunny_480p_surround-fix.avi -ss 60 -t 1 -s 480x300 -f image2 big_buck_bunny_frame.jpg
```

## Transcode with nvidia GPU
```
ffmpeg -y -i big_buck_bunny_480p_surround-fix.avi -vcodec nvenc -b:v 5M -acodec copy big_buck_bunny_480p_surround-fix-nvenc.mp4
```

## Show File Information (Checks inputs & Ouputs) NOT IMPLEMENTED
```
 ffmpeg_build/bin/ffprobe -print_format json big_buck_bunny_480p_surround-fix.avi -v quiet -show_streams  -show_format
```
 
 Output:
 ```
 {
    "streams": [
        {
            "index": 0,
            "codec_name": "mpeg4",
            "codec_long_name": "MPEG-4 part 2",
            "profile": "Simple Profile",
            "codec_type": "video",
            "codec_time_base": "1/24",
            "codec_tag_string": "FMP4",
            "codec_tag": "0x34504d46",
            "width": 854,
            "height": 480,
            "coded_width": 854,
            "coded_height": 480,
            "has_b_frames": 0,
            "sample_aspect_ratio": "1:1",
            "display_aspect_ratio": "427:240",
            "pix_fmt": "yuv420p",
            "level": 1,
            "chroma_location": "left",
            "refs": 1,
            "quarter_sample": "false",
            "divx_packed": "false",
            "r_frame_rate": "24/1",
            "avg_frame_rate": "24/1",
            "time_base": "1/24",
            "start_pts": 0,
            "start_time": "0.000000",
            "duration_ts": 14315,
            "duration": "596.458333",
            "bit_rate": "2500431",
            "nb_frames": "14315",
            "disposition": {
                "default": 0,
                "dub": 0,
                "original": 0,
                "comment": 0,
                "lyrics": 0,
                "karaoke": 0,
                "forced": 0,
                "hearing_impaired": 0,
                "visual_impaired": 0,
                "clean_effects": 0,
                "attached_pic": 0
            }
        },
        {
            "index": 1,
            "codec_name": "ac3",
            "codec_long_name": "ATSC A/52A (AC-3)",
            "codec_type": "audio",
            "codec_time_base": "1/48000",
            "codec_tag_string": "[0] [0][0]",
            "codec_tag": "0x2000",
            "sample_fmt": "fltp",
            "sample_rate": "48000",
            "channels": 6,
            "channel_layout": "5.1(side)",
            "bits_per_sample": 0,
            "dmix_mode": "-1",
            "ltrt_cmixlev": "-1.000000",
            "ltrt_surmixlev": "-1.000000",
            "loro_cmixlev": "-1.000000",
            "loro_surmixlev": "-1.000000",
            "r_frame_rate": "0/0",
            "avg_frame_rate": "0/0",
            "time_base": "1/56000",
            "start_pts": 0,
            "start_time": "0.000000",
            "bit_rate": "448000",
            "nb_frames": "33401088",
            "disposition": {
                "default": 0,
                "dub": 0,
                "original": 0,
                "comment": 0,
                "lyrics": 0,
                "karaoke": 0,
                "forced": 0,
                "hearing_impaired": 0,
                "visual_impaired": 0,
                "clean_effects": 0,
                "attached_pic": 0
            }
        }
    ],
    "format": {
        "filename": "big_buck_bunny_480p_surround-fix.avi",
        "nb_streams": 2,
        "nb_programs": 0,
        "format_name": "avi",
        "format_long_name": "AVI (Audio Video Interleaved)",
        "start_time": "0.000000",
        "duration": "596.458333",
        "size": "220514438",
        "bit_rate": "2957650",
        "probe_score": 100
    }
}
 ```
