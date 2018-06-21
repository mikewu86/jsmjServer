#!/usr/bin/env python
# -*- coding:utf-8 -*-

# author:may@uc888.cn
# date:2017-06-22
import os
import ConfigParser
import argparse
import sys

def main():
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit('No argument receive.')

    args = parser.parse_args()

    if not args.api_file or not args.env or not args.node_name:
        parser.print_help()
        sys.exit('Please check the arguments.')

    #read the conf from api file
    config = read_conf(args.api_file, args.env, args.node_name)

    actions = {
        'create':create,
        'start':start,
        'startnew':start_new,
        'stop':stop,
        'rm':rm,
        'confirm':confirm_upgrade,
    }
    
    actions.get(args.action)(url=config['url'], access_key=config['access_key'], secret_key=config['secret_key'], project_name=config['project'], compose_file=config['node_file'])

def read_conf(api_file, env, node_name):
    params = {}
    with open(api_file) as conf:
        cf = ConfigParser.ConfigParser()
        cf.readfp(conf)

        params['url'] = cf.get(env, 'RANCHER_URL')
        params['access_key'] = cf.get(env, 'RANCHER_ACCESS_KEY')
        params['secret_key'] = cf.get(env, 'RANCHER_SECRET_KEY')
        params['project'] = cf.get(env, 'PROJECT')
        params['node_file'] = os.path.dirname(os.path.abspath(api_file)) + '/' + env + '/' + node_name + '_compose.yml'

    return params

def create(url, access_key, secret_key, project_name, compose_file):
    status = os.system('rancher-compose --url {0} --access-key {1} --secret-key {2} -p {3} -f {4} create'.format(url, access_key, secret_key, project_name, compose_file))
    if status != 0:
        sys.exit('rancher-compose start got error!')
    return status

def start(url, access_key, secret_key, project_name, compose_file):
    status = os.system('rancher-compose --url {0} --access-key {1} --secret-key {2} -p {3} -f {4} start'.format(url, access_key, secret_key, project_name, compose_file))
    if status != 0:
        sys.exit('rancher-compose start got error!')
    return status

def start_new(url, access_key, secret_key, project_name, compose_file):
    status = os.system('rancher-compose --url {0} --access-key {1} --secret-key {2} -p {3} -f {4} up --upgrade -d'.format(url, access_key, secret_key, project_name, compose_file))
    if status != 0:
        sys.exit('rancher-compose startnew got error!')
    return status

def confirm_upgrade(url, access_key, secret_key, project_name, compose_file):
    status = os.system('rancher-compose --url {0} --access-key {1} --secret-key {2} -p {3} -f {4} up --confirm-upgrade -d'.format(url, access_key, secret_key, project_name, compose_file))
    if status != 0:
        sys.exit('rancher-compose confirm_upgrade got error!')
    return status

def stop(url, access_key, secret_key, project_name, compose_file):
    status = os.system('rancher-compose --url {0} --access-key {1} --secret-key {2} -p {3} -f {4} stop'.format(url, access_key, secret_key, project_name, compose_file))
    if status != 0:
        sys.exit('rancher-compose start got error!')
    return status

def rm(url, access_key, secret_key, project_name, compose_file):
    status = os.system('rancher-compose --url {0} --access-key {1} --secret-key {2} -p {3} -f {4} rm'.format(url, access_key, secret_key, project_name, compose_file))
    if status != 0:
        sys.exit('rancher-compose start got error!')
    return status

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Control the rancher service.')
    parser.add_argument('-f', '--file', action='store', dest='api_file', help='Api configuration file.')
    parser.add_argument('-n', '--nodename', action='store', dest='node_name', help='Server node name.')
    parser.add_argument('-e', '--env', action='store', dest='env', help='Publish environment for using.')

    subparsers = parser.add_subparsers(dest='action', help='sub-command')
    #create game service
    subparsers.add_parser('create', help='create the service')

    #start game options
    subparsers.add_parser('start', help='start the service')

    #stop game options
    subparsers.add_parser('stop', help='stop the service')

    #start game with new images options
    upgrade_parser = subparsers.add_parser('startnew', help='upgrade the service')

    #confirm_upgrade
    subparsers.add_parser('confirm', help='confirm upgrade the service')

    #delete game images options
    subparsers.add_parser('rm', help='delete the service')

    main()
