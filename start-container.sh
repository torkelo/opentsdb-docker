#! /bin/bash

docker kill opentsdb-container
docker rm opentsdb-container

docker run -d -p 4242:80 \
	--link serf-container:serf \
	--name opentsdb-container \
	opentsdb