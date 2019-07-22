FROM ubuntu:16.04
MAINTAINER Matt Konda <mkonda@jemurai.com>

################################################################################################
#       Environment
#
RUN apt-get update && apt-get install -y git-core sudo curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libffi-dev libgdbm-dev libncurses5-dev automake libtool bison libffi-dev gnupg patch gawk g++ gcc make libc6-dev libcurl3-dev autoconf libtool ncurses-dev zlib1g libreadline6-dev libreadline6 openssl libcurl4-openssl-dev libgmp-dev clamav md5deep nodejs npm default-jre unzip python python-pip && rm -rf /var/lib/apt/lists/*

RUN echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

#################################################################################################
#       Node Security
#            Early because it needs to run as root.
#            Requires nodejs npm
#
## retirejs locked to most recent pre-2.x.x version (2.x.x breaks the retirejs task)
RUN npm install -g nsp retire@1.6.2 eslint eslint-plugin-scanjs-rules eslint-plugin-no-unsafe-innerhtml
RUN ln -s /usr/bin/nodejs /usr/bin/node

#################################################################################################
#       User
#
RUN useradd -ms /bin/bash --groups sudo glue
USER glue

#################################################################################################
#       RVM / Ruby
#
#
RUN gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN /bin/bash -l -c "curl -L https://get.rvm.io | bash -s stable"
RUN /bin/bash -l -c "source ~/.rvm/scripts/rvm"
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.3.1"
RUN /bin/bash -l -c "rvm use 2.3.1 --default"
RUN /bin/bash -l -c "gem install curb --no-document"
ENV PATH $PATH:/home/glue/.rvm/rubies/ruby-2.3.1/bin

#################################################################################################
#       Python
#
RUN /bin/bash -l -c "sudo pip install --upgrade pip"
RUN /bin/bash -l -c "sudo pip install bandit"
RUN /bin/bash -l -c "sudo pip install awsscout2"

#################################################################################################
#       Java
#
## JDK needed for Dependency Check Maven plugin
RUN sudo apt-get install -y software-properties-common
RUN sudo apt-get update
RUN sudo apt-get install -y default-jre

RUN /bin/bash -l -c "mkdir -p /home/glue/tools"
WORKDIR /home/glue/tools/

#################################################################################################
#       Truffle Hog
#
# RUN /bin/bash -l -c "sudo pip install truffleHog"
RUN git clone https://github.com/runako/truffleHog.git
WORKDIR /home/glue/tools/truffleHog
RUN git checkout rg-local-scan

WORKDIR /home/glue/tools/

# OWASP DEPENDENCY CHECK (needs unzip and default-jre)
RUN curl -L http://dl.bintray.com/jeremy-long/owasp/dependency-check-1.4.3-release.zip --output owasp-dep-check.zip
RUN unzip owasp-dep-check.zip

# Maven
RUN sudo apt-get install -y maven

# FINDBUGS (Experimental)
#RUN curl -L http://downloads.sourceforge.net/project/findbugs/findbugs/3.0.1/findbugs-3.0.1.zip --output findbugs.zip
#RUN unzip findbugs.zip
#RUN curl -L http://search.maven.org/remotecontent?filepath=com/h3xstream/findsecbugs/findsecbugs-plugin/1.4.4/findsecbugs-plugin-1.4.4.jar > findbugs-3.0.1/plugin/findsecbugs.jar
#RUN git clone https://github.com/find-sec-bugs/find-sec-bugs.git

# SBT plugin (for Scala)
RUN sudo apt-get update
RUN echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list
RUN sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823
RUN sudo apt-get install apt-transport-https
RUN sudo apt-get update
RUN sudo apt-get install sbt

RUN mkdir -p /home/glue/.sbt/0.13/plugins
RUN echo "addSbtPlugin(\"net.vonbuchholtz\" % \"sbt-dependency-check\" % \"0.1.4\")" >  /home/glue/.sbt/0.13/plugins/build.sbt

#################################################################################################
#       Glue App
#

## Working Dir
RUN /bin/bash -l -c "mkdir -p /home/glue/tmp"
WORKDIR /home/glue/

## Core Pipeline (and ruby tools)
RUN /bin/bash -l -c "git clone -b better-slack-reporter https://github.com/PastNullInfinity/glue.git"
#RUN /bin/bash -l -c "mkdir -p /home/glue/glue"
ADD . /home/glue/glue

WORKDIR /home/glue/glue
RUN /bin/bash -l -c "gem install bundler; bundle install -j20; rm owasp-glue*.gem; gem build glue.gemspec; gem install owasp-glue*.gem;"

ENTRYPOINT ["glue"]
CMD ["-h"]
