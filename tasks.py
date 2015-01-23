###############################################################################
##                                                                           ##
## The MIT License (MIT)                                                     ##
##                                                                           ##
## Copyright (c) 2014 AT&T Inc.                                              ##
##                                                                           ##
## Permission is hereby granted, free of charge, to any person obtaining     ##
## a copy of this software and associated documentation files                ##
## (the "Software"), to deal in the Software without restriction, including  ##
## without limitation the rights to use, copy, modify, merge, publish,       ##
## distribute, sublicense, and/or sell copies of the Software, and to permit ##
## persons to whom the Software is furnished to do so, subject to the        ##
## conditions as detailed in the file LICENSE.                               ##
##                                                                           ##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS   ##
## OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF                ##
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.    ##
## IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY      ##
## CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT ##
## OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR  ##
## THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                ##
##                                                                           ##
###############################################################################
import os
from invoke import Collection, run, task
from distutils.version import LooseVersion

VIRTUALBOX_VERSION = LooseVersion('4.3')
VMWARE_VERSION = LooseVersion('6.0')
VAGRANT_VERSION = LooseVersion('1.7.2')

@task
def build_docs():
    old_cwd = os.getcwd()
    os.chdir("docs")
    run("make html")
    os.chdir(old_cwd)

@task
def clean_docs():
    old_cwd = os.getcwd()
    os.chdir("docs")
    run("make clean")
    os.chdir(old_cwd)

@task
def validate(provider="vmware"):
    try:
        result = run("vagrant --version", hide=True)
        version = LooseVersion(result.stdout.split()[1].rstrip())
        if VAGRANT_VERSION > version:
            msg = "Detected vagrant %s, suggested %s or greater"
            print(msg % (version, VMWARE_VERSION))
        else:
            print("Found Vagrant version %s....OK" % version)
    except:
        print("Could not find vagrant!")


    if provider == "virtualbox":
        try:
            result = run("VBoxManage --version 2>&1", hide=True)
            version = LooseVersion(result.stdout.rstrip())
            if VIRTUALBOX_VERSION > version:
                msg = "Detected virtualbox %s, sugggested %s or greater."
                print(msg % (version, VIRTUALBOX_VERSION ))
            else:
                print("Found Virtualbox version %s....OK" % version)
        except:
            print("Could not find VBoxManage command!")


    elif provider == "vmware":
        path = "/Applications/VMware\ Fusion.app/Contents"
        cmd = "defaults read %s/Info.plist CFBundleShortVersionString" % path
        try:
            result = run(cmd, hide=True)
            version = LooseVersion(result.stdout.rstrip())
        except:
            print("Could not determine VMware version!")
        if VMWARE_VERSION > version:
            msg = "Detected vmware %s, suggested %s or greater."
            print(msg % (version, VMWARE_VERSION))
        else:
            print("Found VMware version %s....OK" % version)

@task
def test():
    run("py.test")



docs = Collection('docs')
docs.add_task(build_docs, 'build')
docs.add_task(clean_docs, 'clean')
namespace = Collection()
namespace.add_collection(docs)
namespace.add_task(validate)
namespace.add_task(test)