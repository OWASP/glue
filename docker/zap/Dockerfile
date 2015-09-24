FROM owasp/zap2docker-weekly
MAINTAINER Matt Konda <mkonda@jemurai.com>
RUN apt-get install python-pip
RUN pip install --upgrade git+https://github.com/Grunny/zap-cli.git
RUN chown -R zap /zap/
ENV ZAP_PORT 8080
