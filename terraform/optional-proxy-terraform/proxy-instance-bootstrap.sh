#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive 

apt update -y

apt install git python3 python3-venv python3-pip libffi-dev libssl-dev ca-certificates screen -y

pip install --upgrade pip
pip install pipx
pipx install mitmproxy  # Very important to install mitmproxy via pipx and NOT apt or single binary. Weird issues with single binary installs not picking up the cert updates below when connected to gigaproxy.
pipx ensurepath

export PATH=$PATH:~/.local/bin

mitmproxy --version

# Start mitmproxy in a screen session for a short period of time to generate certificates
screen -dmS mitmproxy_bootstrap bash -c "mitmproxy; sleep 10; exit"

sleep 15

screen -S mitmproxy_bootstrap -X quit

openssl x509 -in /root/.mitmproxy/mitmproxy-ca-cert.cer -out /root/.mitmproxy/mitmproxy-ca-cert.pem

MITMPROXY_CERT_PATH="/root/.mitmproxy/mitmproxy-ca-cert.pem"

if [ -f "$MITMPROXY_CERT_PATH" ]; then
    cp "$MITMPROXY_CERT_PATH" /usr/local/share/ca-certificates/mitmproxy-ca-cert.crt
    
    update-ca-certificates
    
    echo "mitmproxy certificate installed into the system's certificate trust store."
else
    echo "mitmproxy certificate not found at $MITMPROXY_CERT_PATH."
fi

cd /root
git clone https://github.com/Sprocket-Security/gigaproxy
cd gigaproxy

screen -dmS mitmproxy_session mitmdump -s gigaproxy.py --set auth_token="${AUTH_TOKEN}" --set proxy_endpoint="${API_ENDPOINT}v1/gigaproxy-forwarder-function" --listen-host 0.0.0.0 --listen-port 8888 --set block_global=false 