FROM ubuntu:latest

ADD package /notebook/

RUN cd /notebook/ ; bash install.sh ; rm -fv install.sh

WORKDIR /notebook

CMD ["bash","run_jupyter"]
