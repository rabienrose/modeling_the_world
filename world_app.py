from __future__ import unicode_literals
from flask import Flask
from flask import request
import sys
import json
import pymongo
import pprint
import config_world
import oss2
import threading
import time
from threading import Thread, Lock
import os

mutex = Lock()
app = Flask(__name__)


@app.route('/query_video_list', methods=['GET'])
def query_video_list():
    db =myclient["model_world"]
    video_col=db["videos"]
    video_infos=[]
    for x in video_col.find({}):
        if "status" in x and x["status"]=="done":
            pass
        else:
            continue
        video_info={}
        video_info["title"]=x["title"]
        video_info["upload_date"]=x["upload_date"]
        video_info["id"]=x["id"]
        video_info["country"]=x["country"]
        video_info["location"]=x["location"]
        video_info["duration"]=x["duration"]
        video_info["file_size"]=x["file_size"]
        video_info["play_pos"]=0
        video_info["played"]=0
        video_info["collected"]=0        
        video_infos.append(video_info)
    return json.dumps(video_infos)

if __name__ == '__main__':
    global myclient
    global pp
    global bucket
    bucket = oss2.Bucket(oss2.Auth(config_world.access_key_id, config_world.access_key_secret), config_world.endpoint, config_world.bucket_name)
    pp=pprint.PrettyPrinter(width=41, compact=True)
    myclient = pymongo.MongoClient(config_world.mongo_conn)
    myclient.server_info()
    app.config['SECRET_KEY'] = 'xxx'
    app.config['UPLOAD_FOLDER'] = './raw'
    app.debug = False
    app.run('0.0.0.0', port=sys.argv[1])