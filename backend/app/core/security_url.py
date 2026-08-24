# ==================================================
# OptigoAI Backend — SSRF & URL Security Defense
# ==================================================
"""
Strict URL validation to prevent Server-Side Request Forgery (SSRF),
internal network scanning, cloud metadata access, and infinite payload abuse.
"""

import ipaddress
import socket
from urllib.parse import urlparse
from typing import Optional, Tuple
from fastapi import HTTPException, status

from app.core.logging import get_logger

logger = get_logger("app.core.security_url")

# Explicitly blocked hostnames
BLOCKED_HOSTNAMES = {
    "localhost",
    "127.0.0.1",
    "::1",
    "0.0.0.0",
    "metadata.google.internal",
    "instance-data",
    "169.254.169.254",
    "metadata.internal",
}


class SecurityURLException(HTTPException):
    def __init__(self, detail: str):
        super().__init__(status_code=status.HTTP_400_BAD_REQUEST, detail=detail)


def validate_and_sanitize_url(url: str) -> str:
    """
    Validate a user-supplied target URL against SSRF attacks.
    Ensures URL uses http/https and does not resolve to loopback, private,
    link-local, or cloud metadata IP addresses.
    """
    if not url or not isinstance(url, str):
        raise SecurityURLException("URL cannot be empty.")

    clean_url = url.strip()
    # If explicit scheme is present (e.g. file://, ftp://, javascript:)
    if "://" in clean_url or clean_url.startswith("file:"):
        try:
            parsed = urlparse(clean_url)
            if parsed.scheme not in ("http", "https"):
                raise SecurityURLException(f"Invalid URL protocol '{parsed.scheme}'. Only HTTP and HTTPS are permitted.")
        except SecurityURLException:
            raise
        except Exception:
            raise SecurityURLException("Malformed URL format.")
    else:
        clean_url = "https://" + clean_url
        try:
            parsed = urlparse(clean_url)
        except Exception:
            raise SecurityURLException("Malformed URL format.")

    hostname = parsed.hostname
    if not hostname:
        raise SecurityURLException("URL must contain a valid domain name.")

    lower_host = hostname.lower().strip(".")

    # 1. Block known forbidden hostnames
    if lower_host in BLOCKED_HOSTNAMES or lower_host.endswith(".local") or lower_host.endswith(".internal"):
        logger.warning("Blocked SSRF attempt targeting forbidden hostname", target=lower_host)
        raise SecurityURLException(f"Access to '{hostname}' is forbidden for security reasons.")

    # 2. Check if hostname is an IP literal
    try:
        ip = ipaddress.ip_address(lower_host)
        _verify_ip_is_public(ip)
    except ValueError:
        # Not an IP literal, resolve DNS to inspect actual target IPs
        _verify_dns_resolution(lower_host)

    return clean_url


def _verify_ip_is_public(ip: ipaddress.IPv4Address | ipaddress.IPv6Address) -> None:
    """Verify that an IP address is publicly routable on the internet."""
    # Explicit AWS / GCP metadata IP
    if str(ip) == "169.254.169.254":
        raise SecurityURLException("Access to cloud metadata endpoints is forbidden.")

    # Allow IPv6 NAT64 prefix (RFC 6052 64:ff9b::/96) commonly used by 5G and modern ISP networks
    if isinstance(ip, ipaddress.IPv6Address):
        nat64_net = ipaddress.ip_network("64:ff9b::/96")
        if ip in nat64_net:
            return

    if (
        ip.is_private
        or ip.is_loopback
        or ip.is_link_local
        or ip.is_multicast
        or ip.is_unspecified
        or (ip.is_reserved and not getattr(ip, "is_global", False))
    ):
        logger.warning("Blocked SSRF attempt targeting non-public IP", ip=str(ip))
        raise SecurityURLException("Target URL resolves to a private, loopback, or restricted IP address.")


def _verify_dns_resolution(hostname: str) -> None:
    """Resolve hostname to check all corresponding IPv4/IPv6 addresses against private IPs."""
    try:
        addr_info = socket.getaddrinfo(hostname, None)
        for entry in addr_info:
            sockaddr = entry[4]
            ip_str = sockaddr[0]
            try:
                ip = ipaddress.ip_address(ip_str)
                _verify_ip_is_public(ip)
            except ValueError:
                continue
    except socket.gaierror:
        # If domain doesn't resolve in test/dev environment, allow for mock development
        from app.core.config import settings
        if settings.is_development or hostname.endswith((".test", ".example", ".invalid")):
            logger.info("Domain not resolvable in local/test environment, allowing for mock crawl", hostname=hostname)
            return
        raise SecurityURLException(f"Could not resolve domain name '{hostname}'. Please check the URL.")

