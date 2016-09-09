
# Java Based Tools
# Dependency Check
RUN mkdir /depcheck
WORKDIR /depcheck
RUN wget http://dl.bintray.com/jeremy-long/owasp/dependency-check-1.3.1-release.zip
RUN unzip dependency-check-1.3.1-release.zip

# ZAP
RUN mkdir /zap
WORKDIR /zap
RUN wget https://github.com/zaproxy/zaproxy/releases/download/2.4.2/ZAP_2.4.2_Linux.tar.gz /zap
RUN tar -zxvf /zap/*.gz

# Node JS Tools
