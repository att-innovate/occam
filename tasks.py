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
from invoke.exceptions import Failure
from distutils.version import LooseVersion

VIRTUALBOX_VERSION = LooseVersion('4.3')
VMWARE_VERSION = LooseVersion('6.0')
VAGRANT_VERSION = LooseVersion('1.7.2')
VMWARE_NETWORK_FILE = "/Library/Preferences/VMware Fusion/networking"

@task
def build_docs():
    """Build documentation."""
    old_cwd = os.getcwd()
    os.chdir("docs")
    run("make html")
    os.chdir(old_cwd)

@task
def clean_docs():
    """Clean all generated documentation files."""
    old_cwd = os.getcwd()
    os.chdir("docs")
    run("make clean")
    os.chdir(old_cwd)

@task
def validate(provider="vmware"):
    """Validate the working environment."""

    try:
        result = run("vagrant --version 2>&1", hide=True)
        version = LooseVersion(result.stdout.split()[1].rstrip())
        if VAGRANT_VERSION > version:
            msg = "Detected vagrant %s, suggested %s or greater"
            print(msg % (version, VMWARE_VERSION))
        else:
            print("Found Vagrant version %s....OK" % version)
    except Failure as e:
        print("Vagrant failed with error: %s" % e.result.stdout)


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


@task(validate)
def demo_start():
    """Create the demo environment."""
    run("vagrant up ops1")

@task
def demo_destroy():
    """Destroy the demo environment."""
    run("vagrant destroy ops1 --force")

@task
def test():
    """Run tests."""
    run("py.test")



docs = Collection('docs')
demo = Collection('demo')

docs.add_task(build_docs, 'build')
docs.add_task(clean_docs, 'clean')

demo.add_task(demo_start, 'start')
demo.add_task(demo_destroy, 'destroy')

namespace = Collection()
namespace.add_collection(docs)
namespace.add_collection(demo)

namespace.add_task(validate)
namespace.add_task(test)
