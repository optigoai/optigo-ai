# ==================================================
# OptigoAI Backend — SSRF & URL Security Tests
# ==================================================

import pytest
from app.core.security_url import validate_and_sanitize_url, SecurityURLException


def test_ssrf_blocks_localhost_and_loopback():
    with pytest.raises(SecurityURLException):
        validate_and_sanitize_url("http://localhost:8000/admin")

    with pytest.raises(SecurityURLException):
        validate_and_sanitize_url("http://127.0.0.1:5432")

    with pytest.raises(SecurityURLException):
        validate_and_sanitize_url("http://0.0.0.0:80")


def test_ssrf_blocks_cloud_metadata_ip():
    with pytest.raises(SecurityURLException):
        validate_and_sanitize_url("http://169.254.169.254/latest/meta-data/")

    with pytest.raises(SecurityURLException):
        validate_and_sanitize_url("http://metadata.google.internal/computeMetadata/v1/")


def test_ssrf_blocks_private_rfc1918_networks():
    with pytest.raises(SecurityURLException):
        validate_and_sanitize_url("http://10.0.0.5/api")

    with pytest.raises(SecurityURLException):
        validate_and_sanitize_url("http://192.168.1.1/router")

    with pytest.raises(SecurityURLException):
        validate_and_sanitize_url("http://172.16.0.1/status")


def test_ssrf_blocks_invalid_protocols():
    with pytest.raises(SecurityURLException):
        validate_and_sanitize_url("file:///etc/passwd")

    with pytest.raises(SecurityURLException):
        validate_and_sanitize_url("ftp://server/data")

    with pytest.raises(SecurityURLException):
        validate_and_sanitize_url("gopher://target")


def test_ssrf_allows_valid_public_domain():
    clean = validate_and_sanitize_url("google.com")
    assert clean == "https://google.com"

    clean_https = validate_and_sanitize_url("https://example.com/about-us")
    assert clean_https == "https://example.com/about-us"
