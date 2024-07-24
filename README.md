<h1 align="center">gigaproxy</h1>

<h3 align="center">The Giga Proxy</h3>

## Why? 
fireprox is great but has one major downside. You can only target a single host at a time. 

Gigaproxy solves this. Check out the blog post [One Proxy to Rule Them All](https://www.sprocketsecurity.com/resources/gigaproxy) for more details on how it works. 

## Getting Started

To use this project and the built-in `gigaproxy.py` script, you will need the following:

- An AWS account with AWS credentials stored locally (AWS SSO session, static access keys, etc.)
- HashiCorp [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) installed
- Python and [pipx](https://github.com/pypa/pipx) installed
- [mitmproxy](https://docs.mitmproxy.org/stable/overview-installation/) installed and in your path
- mitmproxy [certificates](https://docs.mitmproxy.org/stable/concepts-certificates/) installed and trusted on your system


## Build the Infrastructure

First, optionally update the `terraform/variables.tf` with an API key that will be required to authenticate to the generated API gateway endpoint. **If you don't set this yourself, you must go into the AWS console and get it. We recommend specifying your own!**

To build the infrastructure, you can use the following commands:

```bash
cd terraform/
terraform init
terraform plan # optional: if you want to see what's going to be built before running, apply
terraform apply
```

Look for the output `api-endpoint` in your terminal after applying.


## Starting the Proxy

The proxy is started via the command line with arguments to specify the API endpoint and an API key.

```bash
mitmdump -s gigaproxy.py --set auth_token=<api-key> --set proxy_endpoint=<api-endpoint>
```

There are also a couple of secret options that you can use if you read the code. 

If you run this on a VPS somewhere, we recommend tossing it in a tmux or screen session because it will take over your terminal. 

Note that you can specify a custom port and host to listen on. By default, mitmdump will listen on 127.0.0.1:8080. 

For example:

```bash
mitmdump -s gigaproxy.py --set auth_token=<api-key> --set proxy_endpoint=<api-endpoint> --listen-host 0.0.0.0 --listen-port 8888
```


## Testing 

With mitmdump running, you can test if everything is working properly. First, make a file containing multiple public IP retrieval endpoints.

```txt
https://ifconfig.me
https://api.ipify.org
https://ipv4.rawrify.com/ip
```

Then run the following for loop:

```bash
while true; do for i in $(cat endpoints.txt); do curl -s $i -x http://127.0.0.1:8080; done; done
```

Every minute, your public IP should change. 


## Examples 
Run nuclei with the following command:

```bash
nuclei -l endpoints.txt -t /path/to/nuclei-templates/ -p http://127.0.0.1:8888
```

Run ffuf with the following command:

```bash
ffuf -u https://example.com/FUZZ -w ~/.ffufw/wordlists/misc/raft-large-words.txt -ac -x http://127.0.0.1:8888
```

Proxy a specific CLI tool with exported environment variables.

```bash
export http_proxy=http://127.0.0.1:8888
export https_proxy=http://127.0.0.1:8888

# Now run the command you want to proxy
curl https://example.com
```

## TODO

* Add multi-cloud support
* Convert gigaproxy.py to a more portable CLI tool
* Add more examples
* Organize terraform code

## References & Thanks 

* [fireprox](https://github.com/ustayready/fireprox)
* [This guy](https://github.com/Hogman-the-Intruder)
