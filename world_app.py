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

@app.route('/regist', methods=['POST'])
def regist():
    req_data = request.get_json()
    account=req_data["account"]
    password=req_data["password"]
    col = myclient["model_world"]["user"]
    re = col.find_one({"account":account})
    if re is not None:
        return json.dumps({"err":"account_exist"})
    re = col.insert_one({"account":account,"password":password})
    return json.dumps({"token":str(re.inserted_id)})

@app.route('/login', methods=['POST'])
def login():
    req_data = request.get_json()
    print(req_data)
    account=req_data["account"]
    password=req_data["password"]
    col = myclient["model_world"]["user"]
    re = col.find_one({"account":account})
    if re is None:
        return json.dumps({"err":"account_not_exist"})
    if re["password"]!=password:
        return json.dumps({"err":"password_not_right"})
    return json.dumps({"token":str(re["_id"])})

@app.route('/query_subject_list', methods=['GET'])
def query_subject_list():
    subject_info={}
    subject_info["title"]=""
    subject_info["desc"]=""
    subject_info["id"]=""
    subject_info["video_count"]=""
    return json.dumps(subject_info)


@app.route('/query_user_info', methods=['GET'])
def query_user_info():
    return ""

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
    app.debug = True
    app.run('0.0.0.0', port=sys.argv[1])