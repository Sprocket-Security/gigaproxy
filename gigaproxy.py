import argparse
import logging
import os
import random
from urllib.parse import urlparse

from mitmproxy import ctx, http

# Configure logging
logging.basicConfig(level=logging.INFO)


def load(l):
    l.add_option("auth_token", str, "", "Authorization token for the proxy")
    l.add_option(
        "proxy_endpoint", str, "", "Target AWS API gateway endpoint to forward to"
    )
    l.add_option("rotate_user_agent", bool, False, "Rotate the user agent")
    l.add_option("debug", bool, False, "Enable debug mode")


user_agents = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Safari/605.1.15",
    "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1",
    "Mozilla/5.0 (Linux; Android 11; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Mobile Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edge/91.0.864.59",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "Mozilla/5.0 (iPad; CPU OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1",
    "Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Mobile Safari/537.36",
]


def request(flow: http.HTTPFlow) -> None:

    # Access options using ctx.options
    auth_token = ctx.options.auth_token
    proxy_endpoint = ctx.options.proxy_endpoint
    rotate_user_agent = ctx.options.rotate_user_agent
    debug = ctx.options.debug

    try:
        # Adding new required headers for the proxy
        flow.request.headers["x-api-key"] = auth_token
        flow.request.headers["x-forward-me-to"] = flow.request.pretty_url

        # Optional rotating user agent
        if rotate_user_agent:
            flow.request.headers["User-Agent"] = random.choice(user_agents)

        # Debug logs in AWS will be generated
        if debug:
            flow.request.headers["X-DEBUG"] = "SPRKTWASHERE"

        # Setting the target proxy
        flow.request.host = urlparse(proxy_endpoint).hostname
        flow.request.path = urlparse(proxy_endpoint).path
        flow.request.port = 443
        flow.request.scheme = "https"

    except Exception as e:
        logging.error(f"Error processing request: {e}")
        pass
