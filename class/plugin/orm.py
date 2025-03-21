# coding: utf-8

import re
import os
import sys

from mysql import connector


class ORM:
    __DB_PASS = None
    __DB_USER = 'root'
    __DB_PORT = 3306
    __DB_HOST = 'localhost'
    __DB_CONN = None
    __DB_CUR = None
    __DB_ERR = None
    __DB_CNF = '/etc/my.cnf'
    __DB_SOCKET = '/www/server/mysql/mysql.sock'

    def __Conn(self):
        '''连接MYSQL数据库'''
        try:

            if os.path.exists(self.__DB_SOCKET):
                try:
                    self.__DB_CONN = connector.connect(host=self.__DB_HOST, user=self.__DB_USER, passwd=self.__DB_PASS,
                                                       port=self.__DB_PORT, charset="utf8", connect_timeout=1, unix_socket=self.__DB_SOCKET)
                except Exception as e:
                    self.__DB_HOST = '127.0.0.1'
                    self.__DB_CONN = connector.connect(host=self.__DB_HOST, user=self.__DB_USER, passwd=self.__DB_PASS,
                                                       port=self.__DB_PORT, charset="utf8", connect_timeout=1, unix_socket=self.__DB_SOCKET)
            else:
                try:
                    self.__DB_CONN = connector.connect(host=self.__DB_HOST, user=self.__DB_USER, passwd=self.__DB_PASS,
                                                       port=self.__DB_PORT, charset="utf8", connect_timeout=1)
                except Exception as e:
                    self.__DB_HOST = '127.0.0.1'
                    self.__DB_CONN = connector.connect(host=self.__DB_HOST, user=self.__DB_USER, passwd=self.__DB_PASS,
                                                       port=self.__DB_PORT, charset="utf8", connect_timeout=1)

            self.__DB_CUR = self.__DB_CONN.cursor()
            return True
        except Exception as e:
            self.__DB_ERR = e
            return False

    def setDbConf(self, conf):
        self.__DB_CNF = conf

    def setSocket(self, sock):
        self.__DB_SOCKET = sock

    def setPort(self, port):
        self.__DB_PORT = port

    def setPwd(self, pwd):
        self.__DB_PASS = pwd

    def getPwd(self):
        return self.__DB_PASS

    def execute(self, sql):
        # 执行SQL语句返回受影响行
        if not self.__Conn():
            return self.__DB_ERR
        try:
            result = self.__DB_CUR.execute(sql)
            self.__DB_CONN.commit()
            self.__Close()
            return result
        except Exception as ex:
            return ex

    def query(self, sql):
        # 执行SQL语句返回数据集
        if not self.__Conn():
            return self.__DB_ERR
        try:
            self.__DB_CUR.execute(sql)
            result = self.__DB_CUR.fetchall()
            # 将元组转换成列表
            # data = list(map(list, result))
            self.__Close()
            return result
        except Exception as ex:
            return ex

    def __Close(self):
        # 关闭连接
        self.__DB_CUR.close()
        self.__DB_CONN.close()
