FROM ubuntu:14.04
MAINTAINER Matt Konda <mkonda@jemurai.com>
RUN apt-get update && apt-get install -y nodejs npm 
RUN npm install -g retire
RUN ln -s /usr/bin/nodejs /usr/bin/node
CMD [ "retire" , "retire -v" ]

