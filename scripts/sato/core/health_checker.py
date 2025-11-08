#!/usr/bin/env python3
"""
Enhanced Health Checker with Multiple Check Types
"""

import socket
import subprocess
import time
import urllib.request
import urllib.error
import urllib.parse
from typing import Tuple, Optional, List
from enum import Enum
import json
import re


class CheckResult:
    def __init__(
        self,
        is_healthy: bool,
        response_time: int,
        message: str = "",
        status_code: Optional[int] = None,
        details: Optional[dict] = None,
    ):
        self.is_healthy = is_healthy
        self.response_time = response_time
        self.message = message
        self.status_code = status_code
        self.details = details or {}


class HealthChecker:
    def __init__(self):
        self.user_agent = "ServerMonitor/2.0"
        # Performance optimization: cache DNS lookups
        self._dns_cache = {}
        self._last_dns_clear = time.time()

    def check_server(self, server_config, timeout: int = 5) -> CheckResult:
        """Main entry point for server health checks"""
        check_type = (
            server_config.check_type.value
            if hasattr(server_config.check_type, "value")
            else server_config.check_type
        )

        if check_type == "http":
            return self.check_http(server_config, timeout)
        elif check_type == "ping":
            return self.check_ping(server_config, timeout)
        elif check_type == "tcp":
            return self.check_tcp(server_config, timeout)
        elif check_type == "custom":
            return self.check_custom(server_config, timeout)
        else:
            return CheckResult(False, 0, f"Unknown check type: {check_type}")

    def check_http(self, server_config, timeout: int) -> CheckResult:
        """Highly optimized HTTP/HTTPS health check"""
        start_time = time.time()

        try:
            # Build URL
            url = self.build_url(server_config)

            # Use HEAD request by default for faster checks (unless content verification needed)
            need_content_check = (
                hasattr(server_config, "expected_content")
                and server_config.expected_content
            )

            # Create optimized request
            req = urllib.request.Request(url)

            # Use HEAD method for faster checks when content verification not needed
            if not need_content_check:
                req.get_method = lambda: "HEAD"

            # Minimal headers for speed
            req.add_header("User-Agent", "SatoMonitor/1.0")  # Shorter user agent
            req.add_header("Connection", "close")
            req.add_header("Accept", "*/*")
            req.add_header("Cache-Control", "no-cache, no-store")
            req.add_header("Pragma", "no-cache")

            # Add custom headers if specified (but warn about performance impact)
            if (
                hasattr(server_config, "custom_headers")
                and server_config.custom_headers
            ):
                for header, value in server_config.custom_headers.items():
                    req.add_header(header, value)

            # Fast timeout optimization for responsiveness
            actual_timeout = min(
                timeout, 3
            )  # Max 3 seconds for HTTP checks (optimized for quick response)

            # Clear DNS cache periodically for fresh lookups
            current_time = time.time()
            if current_time - self._last_dns_clear > 300:  # Every 5 minutes
                self._dns_cache.clear()
                self._last_dns_clear = current_time

            with urllib.request.urlopen(req, timeout=actual_timeout) as response:
                response_time = int((time.time() - start_time) * 1000)
                status_code = response.getcode()

                # Fast status code check
                expected_codes = getattr(server_config, "expected_status_codes", [200])
                is_healthy = status_code in expected_codes

                # Only read response body if absolutely necessary
                body = ""
                if need_content_check:
                    try:
                        # Read minimal bytes for content verification
                        body = response.read(200).decode("utf-8", errors="ignore")

                        # Quick content check
                        if server_config.expected_content not in body:
                            is_healthy = False
                            message = f"Content missing (HTTP {status_code})"
                        else:
                            message = f"HTTP {status_code} ✓"
                    except:
                        # If content read fails, still consider healthy if status code is good
                        message = f"HTTP {status_code} (content unreadable)"
                else:
                    message = f"HTTP {status_code}"

                # Minimal details for performance
                details = {
                    "status_code": status_code,
                    "method": "HEAD" if not need_content_check else "GET",
                }

                return CheckResult(
                    is_healthy, response_time, message, status_code, details
                )

        except urllib.error.HTTPError as e:
            response_time = int((time.time() - start_time) * 1000)
            status_code = e.code

            # Fast status code check for HTTP errors
            expected_codes = getattr(server_config, "expected_status_codes", [200])
            is_healthy = status_code in expected_codes

            # Simplified error message for speed
            message = f"HTTP {status_code}"
            details = {"status_code": status_code}

            return CheckResult(is_healthy, response_time, message, status_code, details)

        except (urllib.error.URLError, socket.timeout, socket.error) as e:
            response_time = int((time.time() - start_time) * 1000)

            # Fast error categorization
            if isinstance(e, socket.timeout) or "timeout" in str(e).lower():
                message = "Timeout"
            elif "connection" in str(e).lower():
                message = "Connection failed"
            elif (
                "name resolution" in str(e).lower()
                or "name or service not known" in str(e).lower()
            ):
                message = "DNS failed"
            else:
                message = "Network error"

            return CheckResult(
                False, response_time, message, None, {"error_type": type(e).__name__}
            )

        except Exception as e:
            response_time = int((time.time() - start_time) * 1000)
            # Generic fast error handling
            message = "Check failed"
            return CheckResult(
                False, response_time, message, None, {"error_type": type(e).__name__}
            )

    def check_ping(self, server_config, timeout: int) -> CheckResult:
        """ICMP ping health check"""
        start_time = time.time()

        try:
            # Extract hostname from URL if needed
            host = self.extract_hostname(server_config.host)

            # Build ping command based on OS
            try:
                # Try to determine OS
                import platform

                system = platform.system().lower()

                if system == "windows":
                    cmd = ["ping", "-n", "1", "-w", str(timeout * 1000), host]
                else:  # Linux/macOS
                    cmd = ["ping", "-c", "1", "-W", str(timeout), host]

                # Execute ping
                result = subprocess.run(
                    cmd, capture_output=True, text=True, timeout=timeout + 1
                )
                response_time = int((time.time() - start_time) * 1000)

                if result.returncode == 0:
                    # Extract actual ping time from output
                    ping_time = self.extract_ping_time(result.stdout)
                    if ping_time is not None:
                        response_time = ping_time

                    message = f"Ping successful ({response_time}ms)"
                    details = {"ping_output": result.stdout.strip()}

                    return CheckResult(True, response_time, message, None, details)
                else:
                    message = (
                        f"Ping failed: {result.stderr.strip() or 'Host unreachable'}"
                    )
                    details = {"ping_output": result.stderr.strip()}

                    return CheckResult(False, response_time, message, None, details)

            except subprocess.TimeoutExpired:
                response_time = timeout * 1000
                message = f"Ping timeout after {timeout}s"
                return CheckResult(False, response_time, message)

        except Exception as e:
            response_time = int((time.time() - start_time) * 1000)
            message = f"Ping check failed: {str(e)}"
            details = {"error": str(e)}

            return CheckResult(False, response_time, message, None, details)

    def check_tcp(self, server_config, timeout: int) -> CheckResult:
        """TCP socket connection check"""
        start_time = time.time()

        try:
            host = self.extract_hostname(server_config.host)
            port = server_config.port or 80

            # Create socket connection
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(timeout)

            try:
                result = sock.connect_ex((host, port))
                response_time = int((time.time() - start_time) * 1000)

                if result == 0:
                    message = f"TCP connection successful to {host}:{port}"
                    details = {"host": host, "port": port}

                    # Try to send/receive data if specified
                    if (
                        hasattr(server_config, "tcp_send_data")
                        and server_config.tcp_send_data
                    ):
                        try:
                            sock.send(server_config.tcp_send_data.encode())
                            if hasattr(server_config, "tcp_expect_data"):
                                received = sock.recv(1024).decode(
                                    "utf-8", errors="ignore"
                                )
                                if server_config.tcp_expect_data not in received:
                                    message = f"TCP data mismatch on {host}:{port}"
                                    return CheckResult(
                                        False, response_time, message, None, details
                                    )
                        except:
                            pass  # Data exchange is optional

                    return CheckResult(True, response_time, message, None, details)
                else:
                    message = f"TCP connection failed to {host}:{port} (error {result})"
                    details = {"host": host, "port": port, "error_code": result}

                    return CheckResult(False, response_time, message, None, details)

            finally:
                sock.close()

        except socket.timeout:
            response_time = timeout * 1000
            message = f"TCP connection timeout to {host}:{port}"
            return CheckResult(False, response_time, message)

        except Exception as e:
            response_time = int((time.time() - start_time) * 1000)
            message = f"TCP check failed: {str(e)}"
            details = {"error": str(e)}

            return CheckResult(False, response_time, message, None, details)

    def check_custom(self, server_config, timeout: int) -> CheckResult:
        """Custom health check using external command or script"""
        start_time = time.time()

        try:
            if (
                not hasattr(server_config, "custom_command")
                or not server_config.custom_command
            ):
                return CheckResult(False, 0, "No custom command specified")

            # Execute custom command
            cmd = server_config.custom_command
            if isinstance(cmd, str):
                cmd = cmd.split()

            result = subprocess.run(
                cmd, capture_output=True, text=True, timeout=timeout, cwd=None, env=None
            )

            response_time = int((time.time() - start_time) * 1000)

            # Check exit code
            is_healthy = result.returncode == 0

            # Get output
            stdout = result.stdout.strip()
            stderr = result.stderr.strip()

            if is_healthy:
                message = f"Custom check passed"
                if stdout:
                    message += f": {stdout[:100]}"
            else:
                message = f"Custom check failed (exit {result.returncode})"
                if stderr:
                    message += f": {stderr[:100]}"

            details = {
                "exit_code": result.returncode,
                "stdout": stdout,
                "stderr": stderr,
                "command": " ".join(cmd) if isinstance(cmd, list) else cmd,
            }

            return CheckResult(is_healthy, response_time, message, None, details)

        except subprocess.TimeoutExpired:
            response_time = timeout * 1000
            message = f"Custom check timeout after {timeout}s"
            return CheckResult(False, response_time, message)

        except Exception as e:
            response_time = int((time.time() - start_time) * 1000)
            message = f"Custom check error: {str(e)}"
            details = {"error": str(e)}

            return CheckResult(False, response_time, message, None, details)

    def build_url(self, server_config) -> str:
        """Build URL from server configuration"""
        host = server_config.host

        # If it's already a full URL, use it
        if "://" in host:
            # Add custom endpoint if specified
            if (
                hasattr(server_config, "custom_endpoint")
                and server_config.custom_endpoint
            ):
                if not host.endswith("/"):
                    host += "/"
                host += server_config.custom_endpoint.lstrip("/")
            return host

        # Build URL from components
        port = server_config.port
        # Use HTTPS for port 443 or any port ending in 443 (like 5443, 8443)
        protocol = (
            "https" if (port == 443 or (port and str(port).endswith("443"))) else "http"
        )

        if port and port not in [80, 443]:
            url = f"{protocol}://{host}:{port}"
        else:
            url = f"{protocol}://{host}"

        # Add custom endpoint
        if hasattr(server_config, "custom_endpoint") and server_config.custom_endpoint:
            if not url.endswith("/"):
                url += "/"
            url += server_config.custom_endpoint.lstrip("/")

        return url

    def extract_hostname(self, host: str) -> str:
        """Extract hostname from URL or host string"""
        if "://" in host:
            parsed = urllib.parse.urlparse(host)
            return parsed.hostname or parsed.netloc.split(":")[0]

        # Remove port if present
        if ":" in host:
            return host.split(":")[0]

        return host

    def extract_ping_time(self, ping_output: str) -> Optional[int]:
        """Extract ping time from ping command output"""
        try:
            # Look for time=XXXms pattern
            time_match = re.search(
                r"time[=<](\d+(?:\.\d+)?)\s*ms", ping_output, re.IGNORECASE
            )
            if time_match:
                return int(float(time_match.group(1)))

            # Look for XXXms pattern
            time_match = re.search(r"(\d+(?:\.\d+)?)\s*ms", ping_output)
            if time_match:
                return int(float(time_match.group(1)))

            return None
        except:
            return None

    def quick_http_check(self, url: str, timeout: int = 2) -> CheckResult:
        """Ultra-fast HTTP check using HEAD request only"""
        start_time = time.time()

        try:
            req = urllib.request.Request(url)
            req.get_method = lambda: "HEAD"  # HEAD request for maximum speed
            req.add_header("User-Agent", "SatoMonitor/1.0")
            req.add_header("Connection", "close")

            with urllib.request.urlopen(req, timeout=timeout) as response:
                response_time = int((time.time() - start_time) * 1000)
                status_code = response.getcode()

                # Simple success check
                is_healthy = 200 <= status_code < 400
                message = f"HTTP {status_code}"

                return CheckResult(
                    is_healthy, response_time, message, status_code, {"method": "HEAD"}
                )

        except urllib.error.HTTPError as e:
            response_time = int((time.time() - start_time) * 1000)
            is_healthy = 200 <= e.code < 400
            return CheckResult(
                is_healthy, response_time, f"HTTP {e.code}", e.code, {"method": "HEAD"}
            )

        except Exception:
            response_time = int((time.time() - start_time) * 1000)
            return CheckResult(False, response_time, "Failed", None, {"method": "HEAD"})

    def check_internet_connectivity(self) -> bool:
        """Quick internet connectivity check"""
        try:
            # Try to resolve a reliable DNS name
            socket.gethostbyname("google.com")
            return True
        except:
            try:
                # Fallback: try to connect to a reliable service
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(1)  # Reduced timeout for faster check
                result = sock.connect_ex(("8.8.8.8", 53))  # Google DNS
                sock.close()
                return result == 0
            except:
                return False
