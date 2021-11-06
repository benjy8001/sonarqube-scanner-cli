SHELL=/bin/sh

## Colors
ifndef VERBOSE
.SILENT:
endif
COLOR_COMMENT=\033[0;32m
COLOR_INFO=\033[0;33m
COLOR_RESET=\033[0m

IMAGE_PATH=/benjy80/sonarqube-scanner-cli
REGISTRY_DOMAIN=docker.io
VERSION=4.6.2.2472
IMAGE=${REGISTRY_DOMAIN}${IMAGE_PATH}:${VERSION}

## Help
help:
	printf "\n"
	printf "${COLOR_COMMENT}Usage:${COLOR_RESET}\n"
	printf " make [target]\n\n"
	printf "${COLOR_COMMENT}Available targets:${COLOR_RESET}\n"
	awk '/^[a-zA-Z\-\_0-9\.@]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf " ${COLOR_INFO}%-16s${COLOR_RESET} %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)
	printf "\n"


## build and push image
all: build all push_image

## build image and tags it
build: Dockerfile
	docker build -f Dockerfile . -t ${IMAGE}

## login on registry
registry_login:
	docker login ${REGISTRY_DOMAIN}

## push image
push_image: registry_login
	docker push  ${IMAGE}

## Run minimal test
test:
	docker run --rm -v $PWD:/project  -w /project ${IMAGE} sh -c "sonar-scanner -h"
	docker run --rm -v $PWD:/project  -w /project ${IMAGE} sh -c " java -jar /opt/sonar-cnes-report/lib/sonar-cnes-report-3.2.2.jar -h"
	docker run --rm -v $PWD:/project  -w /project ${IMAGE} sh -c " java -jar /opt/sonar-cnes-report/lib/sonar-cnes-report-4.0.0.jar -h"
	#docker run --rm -v $PWD:/project  -w /project ${IMAGE} sh -c "SONAR_PROJECT_KEY=test SONAR_HOST=localhost SONAR_LOGIN=test sonar-cnes-report -h"
