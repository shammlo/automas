#!/usr/bin/env python3
"""
Settings and Configuration Management for Sato Enhanced Monitoring System
"""

import json
import os
from pathlib import Path
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, asdict
from enum import Enum


class CheckType(Enum):
    HTTP = "http"
    PING = "ping"
    TCP = "tcp"
    CUSTOM = "custom"


class ThemeType(Enum):
    DARK = "dark"
    LIGHT = "light"
    AUTO = "auto"


@dataclass
class ServerConfig:
    name: str
    host: str
    type: str = "server"
    port: Optional[int] = None
    icon: Optional[str] = None
    check_type: CheckType = CheckType.HTTP
    check_interval: int = 15  # seconds
    timeout: int = 5  # seconds
    group: str = "Default"
    enabled: bool = True
    custom_endpoint: Optional[str] = None
    expected_status_codes: List[int] = None
    auto_restart: bool = True  # Enable auto-restart by default
    restart_command: Optional[str] = None  # Custom restart command

    def __post_init__(self):
        if self.expected_status_codes is None:
            # Include common successful and expected API response codes
            self.expected_status_codes = [
                200,
                201,
                202,
                204,
                301,
                302,
                304,
                401,
            ]  # Added 401 for auth-required APIs
        if isinstance(self.check_type, str):
            self.check_type = CheckType(self.check_type)


@dataclass
class UISettings:
    theme: ThemeType = ThemeType.DARK
    opacity: float = 0.95
    always_on_top: bool = False
    minimize_to_tray: bool = False
    show_notifications: bool = True
    sound_alerts: bool = False
    auto_hide: bool = False
    compact_mode: bool = False
    window_width: int = 675
    window_height: int = 730
    animation_enabled: bool = True

    def __post_init__(self):
        if isinstance(self.theme, str):
            self.theme = ThemeType(self.theme)


@dataclass
class MonitoringSettings:
    global_check_interval: int = 15  # seconds
    max_response_time_warning: int = 1000  # ms
    max_response_time_critical: int = 5000  # ms
    enable_uptime_tracking: bool = True
    history_retention_days: int = 30
    parallel_checks: bool = True
    max_concurrent_checks: int = 10
    flap_detection_threshold: int = 3  # Number of failures before considering flapping
    flap_detection_window: int = 300  # Time window in seconds
    min_failure_duration: int = 60  # Minimum seconds before alerting


@dataclass
class NotificationSettings:
    desktop_notifications: bool = True
    sound_alerts: bool = False
    webhook_url: Optional[str] = None
    notify_on_status_change: bool = True
    notify_on_slow_response: bool = False
    notification_timeout: int = 5000  # ms
    group_similar_alerts: bool = True  # Group related alerts
    alert_cooldown_seconds: int = 300  # Cooldown between similar alerts
    suppress_flapping_alerts: bool = True  # Suppress alerts for flapping services
    enhanced_notifications: bool = (
        True  # Use enhanced notification system with grouping
    )


class SettingsManager:
    def __init__(self, config_dir: Optional[Path] = None):
        if config_dir is None:
            config_dir = Path(__file__).parent

        self.config_dir = Path(config_dir)
        self.servers_file = self.config_dir / "config" / "config.json"
        self.settings_file = self.config_dir / "config" / "settings.json"
        self.history_file = self.config_dir / "history.json"

        # Ensure config directory exists
        self.config_dir.mkdir(exist_ok=True)

        # Load settings
        self.servers: List[ServerConfig] = []
        self.ui_settings = UISettings()
        self.monitoring_settings = MonitoringSettings()
        self.notification_settings = NotificationSettings()

        self.load_all_settings()

    def load_all_settings(self):
        """Load all configuration files"""
        self.load_servers()
        self.load_settings()

    def load_servers(self) -> List[ServerConfig]:
        """Load server configurations from JSON file"""
        try:
            if self.servers_file.exists():
                with open(self.servers_file, "r") as f:
                    data = json.load(f)
                    servers = []
                    for server_data in data:
                        # Handle legacy config files - add missing fields with defaults
                        if "check_type" not in server_data:
                            server_data["check_type"] = CheckType.HTTP
                        else:
                            # Convert string check_type to enum
                            check_type_str = server_data["check_type"]
                            if isinstance(check_type_str, str):
                                try:
                                    server_data["check_type"] = CheckType(
                                        check_type_str.lower()
                                    )
                                except ValueError:
                                    server_data["check_type"] = CheckType.HTTP

                        if "check_interval" not in server_data:
                            server_data["check_interval"] = 15
                        if "timeout" not in server_data:
                            server_data["timeout"] = 5
                        if "group" not in server_data:
                            server_data["group"] = "Default"
                        if "enabled" not in server_data:
                            server_data["enabled"] = True

                        servers.append(ServerConfig(**server_data))
                    self.servers = servers
            else:
                self.servers = self.create_default_servers()
                self.save_servers()
        except Exception as e:
            print(f"Error loading servers: {e}")
            self.servers = self.create_default_servers()

        return self.servers

    def save_servers(self):
        """Save server configurations to JSON file"""
        try:
            data = [asdict(server) for server in self.servers]
            # Convert enums to strings for JSON serialization
            for server_data in data:
                if "check_type" in server_data:
                    server_data["check_type"] = server_data["check_type"].value

            with open(self.servers_file, "w") as f:
                json.dump(data, f, indent=2)
        except Exception as e:
            print(f"Error saving servers: {e}")

    def load_settings(self):
        """Load UI and monitoring settings"""
        try:
            if self.settings_file.exists():
                with open(self.settings_file, "r") as f:
                    data = json.load(f)

                    if "ui" in data:
                        self.ui_settings = UISettings(**data["ui"])
                    if "monitoring" in data:
                        self.monitoring_settings = MonitoringSettings(
                            **data["monitoring"]
                        )
                    if "notifications" in data:
                        self.notification_settings = NotificationSettings(
                            **data["notifications"]
                        )
        except Exception as e:
            print(f"Error loading settings: {e}")

    def save_settings(self):
        """Save all settings to JSON file"""
        try:
            data = {
                "ui": asdict(self.ui_settings),
                "monitoring": asdict(self.monitoring_settings),
                "notifications": asdict(self.notification_settings),
            }

            # Convert enums to strings for JSON serialization
            if "theme" in data["ui"]:
                data["ui"]["theme"] = data["ui"]["theme"].value

            with open(self.settings_file, "w") as f:
                json.dump(data, f, indent=2)
        except Exception as e:
            print(f"Error saving settings: {e}")

    def create_default_servers(self) -> List[ServerConfig]:
        """Create default server configurations"""
        return [
            ServerConfig(
                name="Example HTTPS Service",
                host="https://httpbin.org/status/200",
                check_type=CheckType.HTTP,
                group="Examples",
            ),
            ServerConfig(
                name="Example HTTP Service",
                host="httpbin.org",
                port=80,
                check_type=CheckType.HTTP,
                group="Examples",
            ),
        ]

    def get_servers_by_group(self) -> Dict[str, List[ServerConfig]]:
        """Group servers by their group attribute"""
        groups = {}
        for server in self.servers:
            group_name = server.group or "Default"
            if group_name not in groups:
                groups[group_name] = []
            groups[group_name].append(server)
        return groups

    def add_server(self, server: ServerConfig):
        """Add a new server configuration"""
        self.servers.append(server)
        self.save_servers()

    def remove_server(self, server_name: str):
        """Remove a server configuration by name"""
        self.servers = [s for s in self.servers if s.name != server_name]
        self.save_servers()

    def update_server(self, old_name: str, new_server: ServerConfig):
        """Update an existing server configuration"""
        for i, server in enumerate(self.servers):
            if server.name == old_name:
                self.servers[i] = new_server
                break
        self.save_servers()

    def get_server_by_name(self, name: str) -> Optional[ServerConfig]:
        """Get a server configuration by name"""
        for server in self.servers:
            if server.name == name:
                return server
        return None
