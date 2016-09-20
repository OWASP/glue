#docker build -f Dockerfile -t owasp/glue:0.6 .
docker build --no-cache -f Dockerfile -t owasp/glue:0.9.1 -t owasp/glue:latest .
