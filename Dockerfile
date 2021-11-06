FROM alpine:latest
LABEL maintainer="Benjamin MABILLE <benjy80@gmail.com>"

COPY ./sonar-scanner-cli/4.6.2.2472 /opt/sonar-scanner

RUN  apk --update add --no-cache openjdk11-jre nodejs  ca-certificates \
	&& ln -s /opt/sonar-scanner/bin/sonar-scanner /usr/bin/sonar-scanner \
	&& chmod +x /opt/sonar-scanner/bin/sonar-scanner

COPY ./sonar-cnes-report /opt/sonar-cnes-report

RUN ln -s /opt/sonar-cnes-report/bin/sonar-cnes-report /usr/bin/sonar-cnes-report \
	&& chmod +x /opt/sonar-cnes-report/bin/sonar-cnes-report
