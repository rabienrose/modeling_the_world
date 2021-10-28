import config_world
import oss2
import os

def convert_a_video(v_id):
    print("start convert:",v_id)
    full_cmd="ffmpeg -i temp.webm -c:v libvpx-vp9 -b:v 0 -crf 45 -pass 1 -f null /dev/null && ffmpeg -f lavfi -i aevalsrc=0 -i temp.webm -c:v libvpx-vp9 -b:v 0 -crf 45 -pass 2 -map 0 -map 1:v -shortest -y out.webm"
    os.system(full_cmd)
    print("finish convert:",v_id)

def download_a_video(v_id, bucket):
    print("start download:",v_id)
    full_v_addr="video/"+v_id+"/main.webm"
    bucket.get_object_to_file(full_v_addr, "temp.webm")
    print("finish download:",v_id)

def upload_a_video(v_id, bucket):
    print("start upload:",v_id)
    full_v_addr="video/"+v_id+"/main_c.webm"
    bucket.put_object_from_file(full_v_addr, "out.webm")
    print("finish upload:",v_id)

bucket = oss2.Bucket(oss2.Auth(config_world.access_key_id, config_world.access_key_secret), config_world.endpoint, config_world.bucket_name)
for x in oss2.ObjectIterator(bucket, prefix="video/", delimiter="/"):
    if bucket.object_exists(x.key+"main.webm") and (not bucket.object_exists(x.key+"main_c.webm")):
        v_id=x.key.split("/")[-2]
        print(v_id)
        download_a_video(v_id, bucket)
        convert_a_video(v_id)
        upload_a_video(v_id, bucket)
        os.remove("temp.webm")
        os.remove("out.webm")