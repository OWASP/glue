#!/bin/bash

# docker run -t -i pipeline/zap:v1 zap-cli quick-scan http://localhost:4000/

docker run -u zap -i pipeline/zap:v1 zap-cli --api-key 123 quick-scan --spider -l Medium -sc -r -o '-config api.key=123' http://www.jemurai.com

