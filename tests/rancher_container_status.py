#! /usr/bin/env python
# encoding:utf-8

import os
import json
import sys
import re

APIBASEURL = 'http://rancher.ucop.io:8080/v1'
ACCESSKEY = '307FFBC01CBDD23822D9'
SECRETKEY = '2kCX6dWgKZcM7EKfyGNtbdKsXfJSfP8hEGvqbwAh'

def getContainerStatus(serviceNames):
    li = list(splitParams(serviceNames))
    print("li ",li)
    for serviceName in li:
        containerAPI = APIBASEURL + '/projects/1a146/environments/1e631/services'
        ret = os.popen('curl -u ' + ACCESSKEY + ':' + SECRETKEY + ' ' + containerAPI)
        if ret:
            data = ret.read()
            containerStatus = json.loads(data)
            for v in containerStatus['data']:
                if v['name'] == serviceName:
                    if v['state'] != 'active' and v['state'] != 'inactive':
                        li.remove(serviceName)
        else:
            return "curl no data get"
    return li

def splitParams(params):
    li = re.compile(r'[a-zA-Z0-9]+')
    name = li.findall(params)
    return name

if __name__ == '__main__':
    print(sys.argv[1])
    print(','.join(getContainerStatus(sys.argv[1])))