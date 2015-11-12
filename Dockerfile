FROM haproxy:1.5

ADD * /haproxy/

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssl

CMD ["bash","/haproxy/start-haproxy.sh"]
