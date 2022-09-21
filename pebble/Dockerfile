FROM ubuntu:focal
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -y \
    && apt install git golang -y
RUN git clone https://github.com/canonical/pebble \
    && cd pebble \
    && go build ./cmd/pebble

FROM python
USER root
COPY --from=0 /pebble/pebble /usr/bin/pebble
RUN mkdir -p /home/app/pebble
ENV PEBBLE /home/app/pebble
COPY 001-layer.yaml /home/app/pebble/layers/001-layer.yaml
COPY script.py /home/app/script.py
ENV PEBBLE_DEBUG 1
ENTRYPOINT ["/usr/bin/pebble", "run"]