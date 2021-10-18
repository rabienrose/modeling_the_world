from __future__ import unicode_literals
from flask import Flask
from flask import request
import sys
import requests
from bs4 import BeautifulSoup
import json
import youtube_dl
import pymongo
import pprint
import config
import oss2
import threading
import time
from threading import Thread, Lock
import os
import urllib.request

mutex = Lock()

download_list=[]
cur_video_id=None
progress_update_step=0

app = Flask(__name__)

class MyLogger(object):
    def debug(self, msg):
        pass

    def warning(self, msg):
        pass

    def error(self, msg):
        print(msg)


def percentage(bytes_consumed, total_bytes):
    global progress_update_step
    progress_update_step=progress_update_step+1
    if progress_update_step>1000:
        progress_update_step=0
        db =myclient["model_world"]
        video_col=db["videos"]  
        video_col.update_one({"id":cur_video_id},{"$set":{"upload_info":{"bytes_consumed":bytes_consumed, "total_bytes":total_bytes},"status":"uploading"}})

def update_download_list():
    global cur_video_id
    while True:
        if len(download_list)>0:
            video_id = download_list[0]
            cur_video_id=video_id
            ydl_opts = {
                'format': '247',
                'logger': MyLogger(),
                'progress_hooks': [my_hook],
                'outtmpl': "temp.webm"
            }
            if os.path.exists("temp.webm.part"):
                os.remove("temp.webm.part")
            with youtube_dl.YoutubeDL(ydl_opts) as ydl:
                global progress_update_step
                progress_update_step=0
                ydl.extract_info('https://www.youtube.com/watch?v='+video_id,download=True)
                bucket.put_object_from_file("video/"+video_id+"/main.webm","temp.webm",progress_callback=percentage)
                db =myclient["model_world"]
                video_col=db["videos"]  
                progress_update_step=0
                video_col.update_one({"id":video_id},{"$set":{"status":"done"}})
                os.remove("temp.webm")
                with mutex:
                    download_list.remove(video_id)
        else:
            time.sleep(1)

def my_hook(d):
    if d['status'] == 'finished':
        pass
    if d['status'] == 'downloading':
        global progress_update_step
        progress_update_step=progress_update_step+1
        if progress_update_step>10:
            progress_update_step=0
            db =myclient["model_world"]
            video_col=db["videos"]  
            video_col.update_one({"id":cur_video_id},{"$set":{"download_info":d,"status":"downloading"}})

@app.route('/clear_download_list', methods=['GET'])
def clear_download_list():
    with mutex:
        global download_list
        download_list=[]
    return json.dumps(['ok'])

@app.route('/download_google_video', methods=['GET'])
def download_google_video():
    video_id = request.values.get("video_id")
    db =myclient["model_world"]
    video_col=db["videos"]
    find_one=False
    for x in video_col.find({"id":video_id}):
        find_one=True
        break
    if find_one==False:
        return json.dumps(['video_info_not_exist'])
    with mutex:
        for item in download_list:
            if video_id==item:
                return json.dumps(["in_download"])
        download_list.append(video_id)
    return json.dumps(['ok'])

@app.route('/new_google_video', methods=['GET'])
def new_google_video():
    video_id = request.values.get("video_id")
    with youtube_dl.YoutubeDL({}) as ydl:
        result = ydl.extract_info('https://www.youtube.com/watch?v='+video_id,download=False)
        video_info={}
        video_info["dislike_count"]=result["dislike_count"]
        video_info["title"]=result["title"]
        video_info["upload_date"]=result["upload_date"]
        video_info["uploader"]=result["uploader"]
        video_info["uploader_id"]=result["uploader_id"]
        video_info["view_count"]=result["view_count"]
        video_info["webpage_url"]=result["webpage_url"]
        video_info["id"]=result["id"]
        video_info["like_count"]=result["like_count"]
        video_info["duration"]=result["duration"]
        video_info["description"]=result["description"]
        video_info["tags"]=result["tags"]
        video_info["thumbnail"]=result["thumbnail"]
        video_info["formats"]=[]
        for f in result["formats"]:
            f_info={}
            f_info["format"]=f["format"]
            f_info["fps"]=f["fps"]
            f_info["quality"]=f["quality"]
            f_info["filesize"]=f["filesize"]
            video_info["formats"].append(f_info)
        response = requests.get(video_info["thumbnail"])
        bucket.put_object("thumbnail/"+video_id+"/main.jpg",response.content)
        db =myclient["model_world"]
        video_col=db["videos"]  
        video_col.update_one({"id":video_id},{"$set":video_info},upsert=True)
    return json.dumps(['ok'])

@app.route('/test_mongodb', methods=['GET'])
def test_mongodb():
    print("test_mongodb")
    test_db =myclient["db_chamo"]
    test_table=test_db["table_chamo"]
    test_table.insert_one({"name":"chamo"})
    for x in test_table.find({"name":"chamo"}):
        print(x)
    return 'test_mongodb'



@app.route('/test_dl', methods=['GET'])
def test_dl():
    video_id = request.values.get("video_id")
    with youtube_dl.YoutubeDL({}) as ydl:
        result = ydl.extract_info('https://www.youtube.com/watch?v='+video_id,download=False)
        pp.pprint(result)
    return 'test_dl'

def reporthook(a, b, c):
    cul_time=time.time()-s_time

@app.route('/test_request', methods=['GET'])
def test_request():
    global s_time
    s_time=time.time()
    url="https://r1---sn-ibj-i3bs.googlevideo.com/videoplayback?expire=1634408865&ei=QcVqYcvhJI6y4gL765jYBQ&ip=118.191.224.189&id=o-AFJQTxAt6oXd6A4s1T19mcMoPuiDVjVcTBeopaHUDBhL&itag=247&aitags=133%2C134%2C135%2C136%2C137%2C160%2C242%2C243%2C244%2C247%2C248%2C271%2C278%2C313&source=youtube&requiressl=yes&mh=wN&mm=31%2C29&mn=sn-ibj-i3bs%2Csn-i3b7knzl&ms=au%2Crdu&mv=m&mvi=1&pl=24&initcwndbps=221250&vprv=1&mime=video%2Fwebm&ns=wZh3gkXX6wmKWqC-UAi9ZVgG&gir=yes&clen=142564466&dur=657.223&lmt=1554109066450649&mt=1634386869&fvip=1&keepalive=yes&fexp=24001373%2C24007246&c=WEB&txp=2316222&n=QGv30JrybAr39dnIM&sparams=expire%2Cei%2Cip%2Cid%2Caitags%2Csource%2Crequiressl%2Cvprv%2Cmime%2Cns%2Cgir%2Cclen%2Cdur%2Clmt&sig=AOq0QJ8wRgIhAPTGLjTMq2adjgMHjy64VT4zPFJ_zyQtj9TU8_RK0R4cAiEA79uwcNrOx4uOmYkZPIjiUirfb5PgGIabZzMQG_B1USk%3D&lsparams=mh%2Cmm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AG3C_xAwRgIhANzhDNrnDbusIznIy941cfT32QqOaYBKb2QebT-lUuKDAiEA1GGxf1hJxABX8WUOGo5bVWG1jzo7LFPP4EXJ1Fx50sk%3D"
    urllib.request.urlretrieve(url, "sss.webm", reporthook=reporthook)
    return 'test_request'

@app.route('/test_bf', methods=['GET'])
def test_bf():
    r = requests.get("https://www.youtube.com/watch?v=goYtZ0vx6Q4")
    # r = requests.get("https://www.baidu.com/")
    
    soup = BeautifulSoup(r.text, 'html.parser')
    all_scripts=soup.find_all('script')
    count=0
    for script in all_scripts:
        script_text=script.get_text()
        find_re=script_text.find('var ytInitialData = ')
        if find_re>=0:
            data_obj = json.loads(script_text[20:-1])
            contents = data_obj["contents"]["twoColumnWatchNextResults"]["results"]["results"]["contents"]
            for c in contents:
                if "videoPrimaryInfoRenderer" in c:
                    titles=c["videoPrimaryInfoRenderer"]["title"]["runs"]
                    for title in titles:
                        print(title["text"])
                    date_text=c["videoPrimaryInfoRenderer"]["dateText"]["simpleText"]
                    print(date_text)
                if "videoSecondaryInfoRenderer" in c:
                    authors=c["videoSecondaryInfoRenderer"]["owner"]["videoOwnerRenderer"]["title"]["runs"]
                    for author in authors:
                        print(author["text"])
        count=count+1
    return '123456'


if __name__ == '__main__':
    global myclient
    global pp
    global bucket
    bucket = oss2.Bucket(oss2.Auth(config.access_key_id, config.access_key_secret), config.endpoint, config.bucket_name)
    pp=pprint.PrettyPrinter(width=41, compact=True)
    myclient = pymongo.MongoClient(config.mongo_conn)
    myclient.server_info()
    t = threading.Thread(target=update_download_list)
    t.start()
    app.config['SECRET_KEY'] = 'xxx'
    app.config['UPLOAD_FOLDER'] = './raw'
    app.debug = False
    app.run('0.0.0.0', port=sys.argv[1])