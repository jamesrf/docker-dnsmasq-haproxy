# What is it?

This is a dockerized-haproxy for local testing.
It was designed for testing Stackato/CF but may
be used for other things

It has two modes:

1) SSL-terminated
- Haproxy set to HTTP balancing and terminating SSL
- A self-signed cert is generated
 
2) TCP
- TCP load balancing


# What does it need?

It must be run on Linux.  It assumes you are using Ubuntu with systemd.

You also need:
  - Docker
  - DNSMasq
  - Bash
  - Perl

# How to use it

1) Build the docker container:

docker build -t haproxy-cf-loadbalancer .
 
2) Run the setup script:

sudo setup.sh



