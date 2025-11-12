#!/usr/bin/env python3
"""
Status History and Uptime Tracking for Server Status Widget
"""

import json
import time
import threading
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict
from collections import defaultdict, deque


@dataclass
class StatusEvent:
    timestamp: float
    server_name: str
    status: str  # "operational", "down", "degraded"
    response_time: int
    message: str = ""

    @property
    def datetime(self) -> datetime:
        return datetime.fromtimestamp(self.timestamp)

    def to_dict(self) -> dict:
        return asdict(self)


@dataclass
class UptimeStats:
    server_name: str
    total_checks: int
    successful_checks: int
    failed_checks: int
    average_response_time: float
    uptime_percentage: float
    last_check: float
    last_status: str

    def to_dict(self) -> dict:
        return asdict(self)


class StatusTracker:
    def __init__(self, history_file: Path, retention_days: int = 30):
        self.history_file = history_file
        self.retention_days = retention_days

        # In-memory storage for recent events
        self.recent_events: deque = deque(
            maxlen=1000
        )  # Keep last 1000 events in memory
        self.response_times: Dict[str, deque] = defaultdict(
            lambda: deque(maxlen=100)
        )  # Last 100 response times per server
        self.uptime_stats: Dict[str, UptimeStats] = {}

        # Thread safety lock
        self._lock = threading.Lock()

        self.load_history()

    def record_status(
        self, server_name: str, status: str, response_time: int, message: str = ""
    ):
        """Record a status check result"""
        timestamp = time.time()

        event = StatusEvent(
            timestamp=timestamp,
            server_name=server_name,
            status=status,
            response_time=response_time,
            message=message,
        )

        # Thread-safe operations
        should_save = False
        with self._lock:
            # Add to recent events
            self.recent_events.append(event)

            # Update response times
            if response_time > 0:
                self.response_times[server_name].append((timestamp, response_time))

            # Update uptime stats
            self.update_uptime_stats(server_name, status, response_time, timestamp)

            # Check if we should save (but don't save while holding the lock)
            should_save = len(self.recent_events) % 10 == 0

        # Save to disk periodically (outside the lock to avoid deadlock)
        if should_save:
            self.save_history()

    def update_uptime_stats(
        self, server_name: str, status: str, response_time: int, timestamp: float
    ):
        """Update uptime statistics for a server"""
        if server_name not in self.uptime_stats:
            self.uptime_stats[server_name] = UptimeStats(
                server_name=server_name,
                total_checks=0,
                successful_checks=0,
                failed_checks=0,
                average_response_time=0.0,
                uptime_percentage=0.0,
                last_check=timestamp,
                last_status=status,
            )

        stats = self.uptime_stats[server_name]
        stats.total_checks += 1
        stats.last_check = timestamp
        stats.last_status = status

        if status == "operational":
            stats.successful_checks += 1
        else:
            stats.failed_checks += 1

        # Update uptime percentage
        stats.uptime_percentage = (stats.successful_checks / stats.total_checks) * 100

        # Update average response time (only for successful checks)
        if status == "operational" and response_time > 0:
            # Simple moving average
            current_avg = stats.average_response_time
            successful_count = stats.successful_checks
            stats.average_response_time = (
                (current_avg * (successful_count - 1)) + response_time
            ) / successful_count

    def get_recent_events(
        self, server_name: Optional[str] = None, limit: int = 50
    ) -> List[StatusEvent]:
        """Get recent status events, optionally filtered by server"""
        events = list(self.recent_events)

        if server_name:
            events = [e for e in events if e.server_name == server_name]

        # Sort by timestamp (newest first) and limit
        events.sort(key=lambda x: x.timestamp, reverse=True)
        return events[:limit]

    def get_response_time_history(
        self, server_name: str, hours: int = 24
    ) -> List[Tuple[float, int]]:
        """Get response time history for a server"""
        cutoff_time = time.time() - (hours * 3600)

        with self._lock:
            history = []
            if server_name in self.response_times:
                # Create thread-safe copy
                for timestamp, response_time in list(self.response_times[server_name]):
                    if timestamp >= cutoff_time:
                        history.append((timestamp, response_time))

        return sorted(history, key=lambda x: x[0])

    def get_recent_response_times(self, server_name: str, limit: int = 20) -> List[int]:
        """Get recent response times for sparkline display"""
        with self._lock:
            if server_name not in self.response_times:
                return []

            # Get the most recent response times (thread-safe copy)
            recent_times = list(self.response_times[server_name])[-limit:]
            return [
                rt[1] for rt in recent_times
            ]  # Return just the response time values

    def get_uptime_stats(self, server_name: str) -> Optional[UptimeStats]:
        """Get uptime statistics for a server"""
        return self.uptime_stats.get(server_name)

    def get_all_uptime_stats(self) -> Dict[str, UptimeStats]:
        """Get uptime statistics for all servers"""
        return self.uptime_stats.copy()

    def get_status_changes(
        self, server_name: str, hours: int = 24
    ) -> List[StatusEvent]:
        """Get status change events for a server"""
        cutoff_time = time.time() - (hours * 3600)

        events = [
            e
            for e in self.recent_events
            if e.server_name == server_name and e.timestamp >= cutoff_time
        ]

        # Filter to only status changes
        status_changes = []
        last_status = None

        for event in sorted(events, key=lambda x: x.timestamp):
            if event.status != last_status:
                status_changes.append(event)
                last_status = event.status

        return status_changes

    def calculate_downtime(self, server_name: str, hours: int = 24) -> float:
        """Calculate total downtime in minutes for a server"""
        status_changes = self.get_status_changes(server_name, hours)

        if not status_changes:
            return 0.0

        downtime_minutes = 0.0
        current_time = time.time()
        cutoff_time = current_time - (hours * 3600)

        # Track downtime periods
        down_start = None

        for event in status_changes:
            if event.status in ["down", "degraded"] and down_start is None:
                down_start = event.timestamp
            elif event.status == "operational" and down_start is not None:
                downtime_minutes += (event.timestamp - down_start) / 60
                down_start = None

        # If still down, count time until now
        if down_start is not None:
            downtime_minutes += (current_time - down_start) / 60

        return downtime_minutes

    def load_history(self):
        """Load status history from disk"""
        try:
            if self.history_file.exists():
                with open(self.history_file, "r") as f:
                    data = json.load(f)

                    # Load recent events
                    if "events" in data:
                        for event_data in data["events"]:
                            event = StatusEvent(**event_data)
                            self.recent_events.append(event)

                    # Load uptime stats
                    if "uptime_stats" in data:
                        for server_name, stats_data in data["uptime_stats"].items():
                            self.uptime_stats[server_name] = UptimeStats(**stats_data)

                    # Load response times
                    if "response_times" in data:
                        for server_name, times in data["response_times"].items():
                            self.response_times[server_name] = deque(
                                [(t[0], t[1]) for t in times], maxlen=100
                            )
        except Exception as e:
            print(f"Error loading history: {e}")

    def save_history(self):
        """Save status history to disk"""
        try:
            with self._lock:
                # Clean old events before saving
                self.cleanup_old_events()

                # Create thread-safe copies to avoid "deque mutated during iteration"
                events_copy = list(self.recent_events)
                uptime_copy = dict(self.uptime_stats)
                response_times_copy = {
                    name: list(times) for name, times in self.response_times.items()
                }

            # Perform file I/O outside the lock to avoid blocking other operations
            data = {
                "events": [event.to_dict() for event in events_copy],
                "uptime_stats": {
                    name: stats.to_dict() for name, stats in uptime_copy.items()
                },
                "response_times": response_times_copy,
            }

            with open(self.history_file, "w") as f:
                json.dump(data, f, indent=2)
        except Exception as e:
            print(f"Error saving history: {e}")

    def cleanup_old_events(self):
        """Remove events older than retention period"""
        cutoff_time = time.time() - (self.retention_days * 24 * 3600)

        # Filter recent events (thread-safe)
        events_to_keep = []
        for event in list(self.recent_events):  # Create a copy first
            if event.timestamp >= cutoff_time:
                events_to_keep.append(event)

        self.recent_events = deque(events_to_keep, maxlen=1000)

        # Filter response times (thread-safe)
        for server_name in list(self.response_times.keys()):  # Create a copy of keys
            times_to_keep = []
            for t, rt in list(self.response_times[server_name]):  # Create a copy
                if t >= cutoff_time:
                    times_to_keep.append((t, rt))

            self.response_times[server_name] = deque(times_to_keep, maxlen=100)

    def export_stats(self, server_name: Optional[str] = None) -> dict:
        """Export statistics for reporting"""
        if server_name:
            stats = self.get_uptime_stats(server_name)
            if stats:
                return {
                    "server": server_name,
                    "stats": stats.to_dict(),
                    "recent_events": [
                        e.to_dict() for e in self.get_recent_events(server_name, 10)
                    ],
                    "response_times": self.get_response_time_history(server_name, 24),
                }
            return {}
        else:
            return {
                "all_stats": {
                    name: stats.to_dict() for name, stats in self.uptime_stats.items()
                },
                "recent_events": [
                    e.to_dict() for e in self.get_recent_events(limit=50)
                ],
            }
