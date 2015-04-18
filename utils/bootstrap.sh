#!/bin/bash
set -e

LOG=/tmp/bootstrap.log

function update() {
    echo "Updating...."
    apt-get update >> $LOG
}

function install() {
    echo "Installing prerequisites...."
    DEBIAN_FRONTEND=noninteractive \
    apt-get install rake \
                    rsync \
                    ruby-net-scp \
                    ruby-rspec \
                    ruby-highline \
                    zsh \
                    curl \
                    ruby-sqlite3 \
                    ruby-stomp -y >> $LOG
    gem install hiera-gpg --no-ri --no-rdoc >> $LOG
    gem install systemu --no-ri --no-rdoc  -v 2.6.4 >> $LOG
    gem install ruby-puppetdb --no-ri --no-rdoc >> $LOG

}

function bootstrap() {
    if [ -z "$1" ];then
        echo -n "No environment requested. "
        echo  "Deploying to default environment production..."
        DEBIAN_FRONTEND=noninteractive rake remote:deploy_ops
    else
        echo "Deploying occam to environment ${1}, zone ${2}...."
        ZONEFILE=$2 DEBIAN_FRONTEND=noninteractive OC_ENVIRONMENT=$1 rake remote:deploy_ops
    fi
}

update
install
bootstrap $1 $2
