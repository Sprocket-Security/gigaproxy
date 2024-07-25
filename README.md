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

## Optional Proxy Instance

If you run into issues with installing/configuring mitmproxy on a host, we provide the option to deploy an EC2 instance along with the rest of the Gigaproxy Terraform build that will install and run mitmproxy automatically. All you need to do is point to the public IP address of the EC2 host instead of `localhost` when proxying requests.

To deploy this host, edit the `terraform/terraform.tfvars.example` file with the following changes:
- remove the `.example` extension from the end of the filename -- `terraform.tfvars.example` -> `terraform.tfvars`
- change `optional_proxy_instance` to `true`
- put your own public IP address in for the value of `proxy_inbound_ip_allowed`, including the netmask (e.g. `"x.x.x.x/32"`)
    - this value is very important as it will control the security group that gives access to your proxy instance -- **IF YOU LEAVE THIS OPEN TO 0.0.0.0/0 AND SOMEONE FIGURES OUT IT'S A PROXY, THEY CAN ROUTE THEIR TRAFFIC THROUGH YOUR GIGAPROXY INFRA**
- put the **public** key of an SSH key pair for the value of `proxy_public_ssh_key` (e.g. `ssh-rsa AAAA...`)
    - although if everything works as desired you *shouldn't* need to SSH into the proxy instance, this gives you the ability to troubleshoot/modify the host as you want

After editing the above values appropriately, you can re-run `terraform apply` as in the above *Build The Infrastructure* section. The public IP address of the proxy EC2 instance will be displayed in your terminal output.

**You will still need to install the mitmproxy certificate on client devices, or disable certificate/ssl/tls verification on your tooling.**

example command run locally with cert validation disabled: `curl -x http://PUBLIC_IP_OF_PROXY_INSTANCE:8888 -k https://ipv4.rawrify.com/ip`
example command run locally with normal parameters (cert successfully installed on client device): `curl -x http://PUBLIC_IP_OF_PROXY_INSTANCE:8888 https://ipv4.rawrify.com/ip`

Some notes on the EC2 instance:
- As mentioned above, access is controlled to the EC2 instance via a security group. While SSH access is secured by the SSH public key, proxy access is not. 
- The instance will run off the latest Ubuntu 22.04 LTS ARM-based AMI available in AWS *at the time of deployment*
    - After deployment, patching and maintenance of the instance is your responsibility and is not automatically handled.
- To save cost, the instance runs as a `t4g.micro` EC2 instance type, which has about 2 vCPU and 1 GB of memory.
- Launching this host will incur more cost since it's a persistently running server (until you shut it down or terminate it). As of this day (07/24/2024), t4g.micro instances cost about $0.0084USD/hour to run.

You are free to inspect all of the proxy host's Terraform code in the `terraform/optional-proxy-terraform/` directory and the `terraform/proxy-instance.tf` Terraform file.


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
nuclei -l endpoints.txt -t /path/to/nuclei-templates/ -x http://127.0.0.1:8888
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
