#! /usr/bin/env python
# encoding: utf-8

#Test with
# /c/Python27/python waf  distclean configure build

from waflib.Configure import conf
from waflib.Task import Task
import waflib.Context


APPNAME='er_zauker'
VERSION='1.1'

top = '.'
out = 'waf_build' 

@conf
def checkErlang(ctx):
    ctx.start_msg("Checking erlang compiler and version")
    out = ctx.cmd_and_log([ctx.env.ERLC,"-help"],output=waflib.Context.STDOUT, 
                          quiet=waflib.Context.BOTH)
    ctx.end_msg(""+out)


def configure(ctx): 
    print('- configuring the project in ' + ctx.path.abspath())
    ctx.check_waf_version(mini='1.7.6')
    ctx.find_program('touch', var='TOUCH')
    #ctx.find_program('erlc', var="ERLC")    
    ctx.find_program('erlc', var="ERLC",
                          path_list=['c:/Program Files (x86)/erl5.8.3/bin/', '/usrl/local/bin']
                          )
    #print(erlc)
    ctx.checkErlang()


# class erlangVersion(Task):
#     def run(self):
#         self.exec_command("");


def dist(ctx):
    ctx.algo='zip'
    # TODO: Use git ls-files to find them out
    # ctx.files     = ctx.path.ant_glob('**/wscript')
    ctx.excl= ' .git waf-* log  **/.waf-1* **/*~ **/*.pyc **/*.swp **/.lock-w*'    

def ciao(ctx):
    print("Wellcome to ER_Zauker Code Indexer")

def build(ctx):
    print("ER_Zauker Build started...")
    print(ctx.env.TOUCH)
    # ctx(rule='touch ${TGT}', target='foo.txt')
    # ctx(rule='cp ${SRC} ${TGT}', source='foo.txt', target='bar.txt')
