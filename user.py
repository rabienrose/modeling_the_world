import hashlib
import time

class User(object):
    account=""
    password=""

    def __init__(self, account, password):
        self.account = account
        self.password = password

    def get_token(self):
        t = time.time()
        t_stamp = int(t)
        strs = self.account + str(t_stamp)
        hl = hashlib.md5()
        hl.update(strs.encode("utf8"))  # 指定编码格式，否则会报错
        token = hl.hexdigest()
        return token

