#! /bin/bash

docker kill opentsdb-container
docker rm opentsdb-container

docker run -d -p 4242:80 \
	--name opentsdb-container \
	opentsdb
