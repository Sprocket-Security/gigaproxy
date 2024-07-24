#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive 

apt update -y

apt install git python3 python3-pip libffi-dev libssl-dev ca-certificates screen -y

pip install --upgrade pip
pip install --ignore-installed mitmproxy

mitmproxy --version

# Start mitmproxy in a screen session for a short period of time to generate certificates
screen -dmS mitmproxy_bootstrap bash -c "mitmproxy; sleep 10; exit"

sleep 15

screen -S mitmproxy_bootstrap -X quit

MITMPROXY_CERT_PATH="/home/ubuntu/.mitmproxy/mitmproxy-ca-cert.pem"

if [ -f "$MITMPROXY_CERT_PATH" ]; then
    cp "$MITMPROXY_CERT_PATH" /usr/local/share/ca-certificates/mitmproxy-ca-cert.crt
    
    update-ca-certificates
    
    echo "mitmproxy certificate installed into the system's certificate trust store."
else
    echo "mitmproxy certificate not found at $MITMPROXY_CERT_PATH."
fi

cd /home/ubuntu
git clone https://github.com/Sprocket-Security/gigaproxy
cd gigaproxy

screen -dmS mitmproxy_session mitmproxy 