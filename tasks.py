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
import sys
import vmfusion

from invoke import Collection, run, task
from distutils.version import LooseVersion
from colors import red, green

VIRTUALBOX_VERSION = LooseVersion('4.3')
VMWARE_VERSION = LooseVersion('6.0')
VAGRANT_VERSION = LooseVersion('1.7.2')
VMWARE_NETWORK_FILE = "/Library/Preferences/VMware Fusion/networking"
DEMO_SUBNET = "192.168.100.0"

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

def validate_vagrant():
    sys.stdout.write(green("Vagrant is found in path..."))
    try:
        run("which vagrant", hide=True)
        print(green("OK"))
    except:
        print(red("FAIL"))

    msg = green("Vagrant version is {0} or greater...".format(VAGRANT_VERSION))
    sys.stdout.write(msg)

    try:
        result = run("vagrant --version 2>&1", hide=True)
        version = LooseVersion(result.stdout.split()[1].rstrip())

        if VAGRANT_VERSION > version:
            print(red("FAIL"))
        else:
            print(green("OK"))
    except:
        msg = "WARNING:: Vagrant command failed with error, please verify the "
        msg += "vagrant install."
        print(red(msg))

def validate_vmware():
    path = "/Applications/VMware\ Fusion.app/Contents"
    cmd = "defaults read %s/Info.plist CFBundleShortVersionString" % path

    # find a validly configured vmware custom network
    found = False
    for num in range(1,9):
        try:
            net = vmfusion.vnet_cli("vmnet{0}".format(num))
            if net.subnet == DEMO_SUBNET:
                found = True
                break
        except ValueError:
            # network is not defined
            pass

    sys.stdout.write(green("Found custom demo net {0}...".format(DEMO_SUBNET)))

    if found:
        print(green("OK"))
        sys.stdout.write(green("Custom net DHCP is disabled..."))
        if net.dhcp:
            print(red("FAIL"))
        else:
            print(green("OK"))
    else:
        print(red("FAIL"))

    msg = "Checking VMware version {0} or greater...".format(VMWARE_VERSION)
    sys.stdout.write(green(msg))

    try:
        result = run(cmd, hide=True)
        version = LooseVersion(result.stdout.rstrip())
    except:
        print(red("\nWARNING:: Could not determine VMware version!"))
        version = LooseVersion("0.0")

    if VMWARE_VERSION > version:
        print(red("FAIL"))
    else:
        print(green("OK"))


def validate_virtualbox():
    try:
        result = run("VBoxManage --version 2>&1", hide=True)
        version = LooseVersion(result.stdout.rstrip())
        if VIRTUALBOX_VERSION > version:
            msg = "Detected virtualbox %s, sugggested %s or greater."
            print(msg % (version, VIRTUALBOX_VERSION ))
        else:
            print(green("Found Virtualbox version {0}....OK".format(version)))
    except:
        print(red("Could not find VBoxManage command!"))


def rvm_warning():
    path = os.path.join(os.path.expanduser("~"), ".rvm")
    if os.path.exists(path):
        msg = "WARNING:: RVM detected. RVM does magical things to your shell.\n"
        msg += "WARNING:: Helper scripts may not work if vagrant is installed\n"
        msg += "          via RVM. Please consider a standard vagrant install.\n"
        msg += "WARNING:: Vagrant installer can be downloaded at \n"
        msg += "          https://www.vagrantup.com/downloads.html"
        print(red(msg))

@task
def validate(provider="vmware"):
    """Validate the working environment."""
    rvm_warning()
    validate_vagrant()

    if provider == "virtualbox":
        validate_virtualbox()
    elif provider == "vmware":
        validate_vmware()


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
