# Bitfusion Video Transcoding Service

This system currently is designe specifically around videos modification tasks.  As an input file it will take one video file carry out the task and return the Video back.

* CPU & GPU enabled 
* Cuda 7.5
* Nvidia Driver 352
* wget http://developer.download.nvidia.com/compute/nvenc/v5.0/nvenc_5.0.1_sdk.zip -O sdk.zip
* unzip sdk.zip
* 

## Bitfusion FFMPEG API


| METHOD       | URI                                 | ACTION                                            |
|--------------|-------------------------------------|---------------------------------------------------|   
| POST         | http://[hostname]/input/            | Upload a video file                               | 
| GET          | http://[hostname]/input/            | List all uploaded files                           |
| DELETE       | http://[hostname]/input/{file_name} | Delete an uploaded file                           |
| POST         | http://[hostname]/job/              | Submit a ffmpeg job & return a task ID            |
| GET          | http://[hostname]/job/{id}          | Get job status based on the returned task ID      |
| GET          | http://[hostname]/output/           | List output files available                       |
| GET          | http://[hostname]/output/file_name  | Download the output file                          |
| DELETE       | http://[hostname]/output/file_name  | delete output file                                |



## API Token

When the system starts, the API token will be set to the instance-id.  You will need to pass the
header 'X-Auth-Token' and have it set to the instance ID for any of the calls to function.

### Example:

ENCODE A VIDEO SEQUENCE FOR THE IPPOD/IPHONE

```
ffmpeg -i source_video.avi input -acodec aac -ab 128kb -vcodec mpeg4 -b 1200kb -mbd 2 -flags +4mv+trell -aic 2 -cmp 2 -subcmp 2 -s 320x180 -title X final_video.mp4
```


