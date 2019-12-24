# -*- coding: utf-8 -*-
import configparser,sys

file_path = sys.argv[1]
section = sys.argv[2]
option = sys.argv[3]

conf = configparser.ConfigParser()
conf.read(file_path)

value = conf.get(section, option)
print(value)