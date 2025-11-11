#!/usr/bin/env python3
"""
Performance Optimizer for Sato Enhanced Monitoring System
"""

import time
import threading
from typing import Dict, List, Optional
from concurrent.futures import ThreadPoolExecutor, as_completed
import queue


class PerformanceOptimizer:
    """Optimizes monitoring performance through various techniques"""

    def __init__(self, max_workers: int = 5):
        self.max_workers = max_workers
        self.executor = ThreadPoolExecutor(max_workers=max_workers)
        self.check_cache = {}
        self.cache_ttl = 5  # seconds (reduced for more responsive updates)
        self.last_cleanup = time.time()

    def parallel_health_checks(self, servers, health_checker, timeout=5):
        """Perform health checks in parallel with immediate result processing"""
        results = {}
        futures = {}

        # Submit all checks to thread pool
        for i, server in enumerate(servers):
            if getattr(server, "enabled", True):
                future = self.executor.submit(
                    self._cached_health_check, health_checker, server, timeout
                )
                futures[future] = i

        # Collect results as they complete (no timeout - get results immediately)
        for future in as_completed(futures):
            server_index = futures[future]
            try:
                results[server_index] = future.result()
            except Exception as e:
                # Create error result
                from .health_checker import CheckResult

                results[server_index] = CheckResult(False, 0, f"Check failed: {str(e)}")

        return results

    def parallel_health_checks_streaming(
        self, servers, health_checker, result_callback, timeout=5
    ):
        """Perform health checks in parallel with streaming results (immediate updates)"""
        futures = {}

        # Submit all checks to thread pool
        for i, server in enumerate(servers):
            if getattr(server, "enabled", True):
                future = self.executor.submit(
                    self._cached_health_check, health_checker, server, timeout
                )
                futures[future] = i

        # Process results as they complete immediately
        for future in as_completed(futures):
            server_index = futures[future]
            try:
                result = future.result()
                # Call callback immediately when result is ready
                result_callback(server_index, result)
            except Exception as e:
                # Create error result and call callback
                from .health_checker import CheckResult

                error_result = CheckResult(False, 0, f"Check failed: {str(e)}")
                result_callback(server_index, error_result)

    def _cached_health_check(self, health_checker, server, timeout):
        """Health check with caching for frequently checked services"""
        cache_key = f"{server.name}_{server.host}"
        current_time = time.time()

        # Check cache first
        if cache_key in self.check_cache:
            cached_result, cached_time = self.check_cache[cache_key]
            if current_time - cached_time < self.cache_ttl:
                return cached_result

        # Perform actual check
        result = health_checker.check_server(server, timeout)

        # Cache the result
        self.check_cache[cache_key] = (result, current_time)

        # Cleanup old cache entries periodically
        if current_time - self.last_cleanup > 60:  # Every minute
            self._cleanup_cache()
            self.last_cleanup = current_time

        return result

    def _cleanup_cache(self):
        """Remove expired cache entries"""
        current_time = time.time()
        expired_keys = [
            key
            for key, (_, cached_time) in self.check_cache.items()
            if current_time - cached_time > self.cache_ttl * 2
        ]

        for key in expired_keys:
            del self.check_cache[key]

    def optimize_check_intervals(self, servers):
        """Optimize check intervals based on service reliability"""
        for server in servers:
            # Increase interval for consistently healthy services
            if hasattr(server, "_consecutive_success"):
                if server._consecutive_success > 10:
                    # Increase interval for stable services
                    server.check_interval = min(server.check_interval * 1.2, 60)
                elif server._consecutive_success < 3:
                    # Decrease interval for unstable services
                    server.check_interval = max(server.check_interval * 0.8, 10)
            else:
                server._consecutive_success = 0

    def batch_docker_checks(self, docker_services):
        """Batch Docker container checks for efficiency"""
        if not docker_services:
            return {}

        try:
            import subprocess
            from .health_checker import CheckResult

            start_time = time.time()

            # Single command to get all container statuses
            result = subprocess.run(
                ["docker", "ps", "-a", "--format", "{{.Names}}\t{{.Status}}"],
                capture_output=True,
                text=True,
                timeout=5,
            )

            if result.returncode != 0:
                # Return error for all services
                return {
                    i: CheckResult(False, 0, "Docker command failed")
                    for i, _ in enumerate(docker_services)
                }

            # Parse results
            container_status = {}
            for line in result.stdout.strip().split("\n"):
                if "\t" in line:
                    name, status = line.split("\t", 1)
                    container_status[name] = "Up" in status

            # Generate results for each service
            results = {}
            response_time = int((time.time() - start_time) * 1000)

            for i, (service_index, service) in enumerate(docker_services):
                if hasattr(service, "containers"):
                    running_count = sum(
                        1
                        for container in service.containers
                        if container_status.get(container.get("name", ""), False)
                    )
                    total_count = len(service.containers)

                    if running_count == total_count:
                        results[service_index] = CheckResult(
                            True, response_time, f"All {total_count} containers running"
                        )
                    elif running_count > 0:
                        result = CheckResult(
                            False,
                            response_time,
                            f"{running_count}/{total_count} containers running",
                        )
                        result.is_degraded = True
                        results[service_index] = result
                    else:
                        results[service_index] = CheckResult(
                            False, response_time, "No containers running"
                        )
                else:
                    results[service_index] = CheckResult(
                        False, response_time, "No containers configured"
                    )

            return results

        except Exception as e:
            # Return error for all services
            return {
                service_index: CheckResult(
                    False, 0, f"Docker batch check failed: {str(e)}"
                )
                for service_index, _ in docker_services
            }

    def shutdown(self):
        """Cleanup resources"""
        self.executor.shutdown(wait=True)
        self.check_cache.clear()


class FastHealthChecker:
    """Optimized health checker with reduced overhead"""

    def __init__(self):
        self.user_agent = "SatoMonitor/1.0"
        self._session_cache = {}

    def quick_http_check(self, url, timeout=1.5):
        """Ultra-fast HTTP check with minimal overhead"""
        import urllib.request
        from .health_checker import CheckResult

        start_time = time.time()

        try:
            # Use HEAD request for maximum speed
            req = urllib.request.Request(url)
            req.get_method = lambda: "HEAD"
            req.add_header("User-Agent", self.user_agent)
            req.add_header("Connection", "close")
            req.add_header("Cache-Control", "no-cache")

            with urllib.request.urlopen(req, timeout=timeout) as response:
                response_time = int((time.time() - start_time) * 1000)
                status_code = response.getcode()

                is_healthy = 200 <= status_code < 400
                return CheckResult(is_healthy, response_time, f"HTTP {status_code}")

        except urllib.request.HTTPError as e:
            response_time = int((time.time() - start_time) * 1000)
            is_healthy = 200 <= e.code < 400
            return CheckResult(is_healthy, response_time, f"HTTP {e.code}")

        except Exception:
            response_time = int((time.time() - start_time) * 1000)
            return CheckResult(False, response_time, "Failed")

    def quick_tcp_check(self, host, port, timeout=2):
        """Fast TCP connection check"""
        import socket
        from .health_checker import CheckResult

        start_time = time.time()

        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(timeout)
            result = sock.connect_ex((host, port))
            sock.close()

            response_time = int((time.time() - start_time) * 1000)

            if result == 0:
                return CheckResult(True, response_time, "TCP connection successful")
            else:
                return CheckResult(
                    False, response_time, f"TCP connection failed: {result}"
                )

        except Exception as e:
            response_time = int((time.time() - start_time) * 1000)
            return CheckResult(False, response_time, str(e))
