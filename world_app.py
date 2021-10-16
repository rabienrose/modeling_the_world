from __future__ import unicode_literals
from flask import Flask
from flask import request
import sys
import requests
from bs4 import BeautifulSoup
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
    pass

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