FROM ubuntu:14.04
MAINTAINER Matt Konda <mkonda@jemurai.com>

################################################################################################
#       Environment
#
RUN apt-get update && apt-get install -y git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libffi-dev libgdbm-dev libncurses5-dev automake libtool bison libffi-dev gnupg patch gawk g++ gcc make libc6-dev libcurl3-dev autoconf libtool ncurses-dev zlib1g libreadline6-dev libreadline6 openssl libcurl4-openssl-dev libgmp-dev clamav md5deep nodejs npm


#################################################################################################
#       Node Security
#            Early because it needs to run as root.
#
RUN npm install -g nsp retire eslint scanjs eslint-plugin-scanjs-rules eslint-plugin-no-unsafe-innerhtml
RUN ln -s /usr/bin/nodejs /usr/bin/node

#################################################################################################
#       User
#         
RUN useradd -ms /bin/bash pipe
USER pipe

#################################################################################################
#       RVM / Ruby
#
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
RUN /bin/bash -l -c "curl -L https://get.rvm.io | bash -s stable"
RUN /bin/bash -l -c "source ~/.rvm/scripts/rvm"
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.2.2"
RUN /bin/bash -l -c "rvm use 2.2.2 --default"
RUN /bin/bash -l -c "gem install curb"
ENV PATH $PATH:/home/pipe/.rvm/rubies/ruby-2.2.2/bin

#################################################################################################
# Pipeline App
#

## Working Dir
RUN /bin/bash -l -c "mkdir -p /home/pipe/line/tmp"
WORKDIR /home/pipe/line

## Core Pipeline (and ruby tools)
RUN /bin/bash -l -c "git clone https://github.com/OWASP/pipeline.git"
WORKDIR /home/pipe/line/pipeline
RUN /bin/bash -l -c "gem install bundler; bundle install -j20; rm pipeline*.gem; gem build pipeline.gemspec; gem install pipeline*.gem;"

ENTRYPOINT ["pipeline", "-a", "-d"]
CMD ["https://github.com/Jemurai/triage.git"]


