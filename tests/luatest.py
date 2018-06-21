#! /usr/bin/python
# -*- coding: utf-8 -*-

import os,sys
import commands

def getFileName(path):
    fileLists = []
    ''' 获取指定目录下的所有指定后缀的文件名 '''
    for root, dirs, files in os.walk(path):
        for file in files:
            if file.endswith(".lua"):
                #print(os.path.join(root, file))
                fileLists.append(os.path.join(root, file))

    exitCode = 0
    for luaFile in fileLists:
        code, msg = commands.getstatusoutput('luac -p ' + luaFile + ' > /dev/null')
        if code != 0:
            exitCode = code
            print msg

    print("exitcode is:" + str(exitCode))
    return exitCode


if __name__ == '__main__':
    path = os.getcwd()
    eCode = getFileName(path)
    if eCode > 0:
        print("eCode is:" + str(eCode))
        sys.exit(1)
    else:
        sys.exit(0)