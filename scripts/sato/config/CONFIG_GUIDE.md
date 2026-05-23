# 📋 Sato Configuration Guide

## 🎯 Quick Start

1. **Copy the example config:**

   ```bash
   cp config/config.json.example config/config.json
   ```

2. **Edit `config/config.json`** with your services

3. **Run Sato:**
   ```bash
   python3 sato.py
   ```

---

## 📝 Configuration Fields

### **Required Fields**

| Field  | Type   | Description                                  | Example                                            |
| ------ | ------ | -------------------------------------------- | -------------------------------------------------- |
| `name` | string | Display name for the service                 | `"API Gateway Dev"`                                |
| `host` | string | Hostname or URL                              | `"api.example.com"` or `"https://api.example.com"` |
| `type` | string | Service type: `server`, `database`, `docker` | `"server"`                                         |

### **Optional Fields**

| Field                   | Type    | Default | Description                                   |
| ----------------------- | ------- | ------- | --------------------------------------------- |
| `port`                  | number  | -       | Port number (if not in URL)                   |
| `icon`                  | string  | `"🔵"`  | Emoji icon for the service                    |
| `expected_status_codes` | array   | `[200]` | HTTP status codes considered healthy          |
| `check_interval`        | number  | `60`    | Seconds between health checks                 |
| `timeout`               | number  | `5`     | Request timeout in seconds                    |
| `auto_restart`          | boolean | `false` | Auto-restart on failure (local services only) |
| `restart_command`       | string  | `null`  | Command to restart the service                |

---

## 🌐 Service Types

### **1. HTTP/HTTPS Servers**

```json
{
  "name": "My API",
  "host": "https://api.mycompany.com",
  "type": "server",
  "icon": "🌐",
  "expected_status_codes": [200, 401],
  "check_interval": 120,
  "timeout": 10
}
```

**Use Cases:**

- REST APIs
- Web applications
- Microservices
- External APIs

**Tips:**

- Use longer `check_interval` (120s) for external APIs
- Include authentication status codes (401, 403) if needed
- Set higher `timeout` (10s) for slow external services

---

### **2. Databases**

```json
{
  "name": "PostgreSQL",
  "host": "localhost",
  "port": 5432,
  "type": "database",
  "icon": "🐘",
  "check_interval": 60,
  "timeout": 5
}
```

**Supported Databases:**

- PostgreSQL (port 5432) 🐘
- MySQL/MariaDB (port 3306) 🐬
- MongoDB (port 27017) 🍃
- Redis (port 6379) 📦

---

### **3. Docker Services**

Docker services are **auto-discovered** - no configuration needed!

Sato automatically detects:

- Running containers
- Container health status
- Service grouping by prefix

**Example Auto-Discovered Services:**

```
🐳 API Gateway (4 containers)
🐳 Payment Service (2 containers)
🐳 Auth Service (1 container)
```

---

## 🎨 Icon Reference

Choose from these common service icons:

| Icon | Service Type | Example          |
| ---- | ------------ | ---------------- |
| 🌐   | API Gateway  | External APIs    |
| 🚀   | Production   | Live services    |
| 🧪   | Testing      | UAT/Staging      |
| 👨‍💻   | Admin        | Admin panels     |
| 👤   | User         | User-facing APIs |
| 🐘   | PostgreSQL   | Databases        |
| 🐬   | MySQL        | Databases        |
| 🍃   | MongoDB      | NoSQL            |
| 📦   | Redis        | Cache            |
| 🔐   | Auth         | Authentication   |
| 💳   | Payment      | Payment services |
| 📧   | Email        | Mail services    |
| 📱   | Mobile       | Mobile backends  |
| 🛠️   | Tools        | Dev tools        |

---

## 📊 Environment Examples

### **Development Environment**

```json
[
  {
    "name": "Local API",
    "host": "http://localhost:3000",
    "type": "server",
    "icon": "💻",
    "auto_restart": true,
    "restart_command": "npm run dev"
  },
  {
    "name": "Local PostgreSQL",
    "host": "localhost",
    "port": 5432,
    "type": "database",
    "icon": "🐘"
  },
  {
    "name": "Local Redis",
    "host": "localhost",
    "port": 6379,
    "type": "database",
    "icon": "📦"
  }
]
```

---

### **Multi-Environment Setup**

```json
[
  {
    "name": "Dev API",
    "host": "https://api-dev.mycompany.com",
    "type": "server",
    "icon": "💻",
    "check_interval": 60
  },
  {
    "name": "Staging API",
    "host": "https://api-staging.mycompany.com",
    "type": "server",
    "icon": "🧪",
    "check_interval": 90
  },
  {
    "name": "Production API",
    "host": "https://api.mycompany.com",
    "type": "server",
    "icon": "🚀",
    "check_interval": 120,
    "expected_status_codes": [200]
  }
]
```

---

### **Microservices Architecture**

```json
[
  {
    "name": "API Gateway",
    "host": "https://gateway.mycompany.com",
    "type": "server",
    "icon": "🌐"
  },
  {
    "name": "Auth Service",
    "host": "https://auth.mycompany.com",
    "type": "server",
    "icon": "🔐"
  },
  {
    "name": "User Service",
    "host": "https://users.mycompany.com",
    "type": "server",
    "icon": "👤"
  },
  {
    "name": "Payment Service",
    "host": "https://payments.mycompany.com",
    "type": "server",
    "icon": "💳"
  }
]
```

---

## ⚙️ Advanced Configuration

### **Auto-Restart (Local Services Only)**

```json
{
  "name": "Local API",
  "host": "http://localhost:3000",
  "type": "server",
  "icon": "💻",
  "auto_restart": true,
  "restart_command": "systemctl restart my-api"
}
```

⚠️ **Warning:** Only use `auto_restart` for local services you control!

---

### **Custom Health Check Intervals**

```json
{
  "name": "Critical Service",
  "host": "https://critical.mycompany.com",
  "type": "server",
  "check_interval": 30,
  "timeout": 5
}
```

**Recommended Intervals:**

- **Critical services:** 30-60 seconds
- **Standard services:** 60-90 seconds
- **External APIs:** 120+ seconds

---

### **Multiple Status Codes**

```json
{
  "name": "API with Auth",
  "host": "https://api.mycompany.com",
  "type": "server",
  "expected_status_codes": [200, 401, 403]
}
```

**Common Patterns:**

- `[200]` - Public endpoints
- `[200, 401]` - Protected endpoints (401 = healthy but needs auth)
- `[200, 301, 302]` - Services with redirects
- `[200, 401, 403]` - Services with role-based access

---

## 🔧 Troubleshooting

### **Service Not Detected**

1. Check the URL format:

   ```json
   ✅ "https://api.example.com"
   ✅ "api.example.com"
   ❌ "api.example.com/" (trailing slash)
   ```

2. Verify port configuration:
   ```json
   ✅ "host": "api.example.com", "port": 5443
   ✅ "host": "https://api.example.com:5443"
   ```

### **False Positives**

If a service shows as "down" but it's actually up:

1. **Increase timeout:**

   ```json
   "timeout": 10
   ```

2. **Add expected status codes:**

   ```json
   "expected_status_codes": [200, 401, 403]
   ```

3. **Increase check interval:**
   ```json
   "check_interval": 120
   ```

### **Too Many Notifications**

Enable smart notification rules (automatic):

- Grouped notifications for multiple failures
- Flap detection for unstable services
- Only notifies on state changes (UP→DOWN, DOWN→UP)

---

## 📚 Examples by Use Case

### **Freelancer/Solo Developer**

```json
[
  {
    "name": "Client Project API",
    "host": "https://api.client.com",
    "type": "server",
    "icon": "🚀"
  },
  {
    "name": "Local Dev Server",
    "host": "http://localhost:3000",
    "type": "server",
    "icon": "💻"
  }
]
```

### **Startup Team**

```json
[
  {
    "name": "Production API",
    "host": "https://api.mystartup.com",
    "type": "server",
    "icon": "🚀",
    "check_interval": 60
  },
  {
    "name": "Staging API",
    "host": "https://staging.mystartup.com",
    "type": "server",
    "icon": "🧪"
  },
  {
    "name": "Database",
    "host": "db.mystartup.com",
    "port": 5432,
    "type": "database",
    "icon": "🐘"
  }
]
```

### **Enterprise/DevOps**

```json
[
  {
    "name": "Prod API Gateway",
    "host": "https://api.company.com",
    "type": "server",
    "icon": "🌐",
    "check_interval": 120
  },
  {
    "name": "Prod Auth Service",
    "host": "https://auth.company.com",
    "type": "server",
    "icon": "🔐",
    "check_interval": 120
  },
  {
    "name": "Monitoring Dashboard",
    "host": "https://monitoring.company.com",
    "type": "server",
    "icon": "📊"
  }
]
```

---

## 🎯 Best Practices

1. **Start Small:** Begin with 3-5 critical services
2. **Use Clear Names:** Make service names descriptive
3. **Choose Appropriate Icons:** Visual identification helps
4. **Set Realistic Intervals:** Don't overwhelm external APIs
5. **Group by Environment:** Dev, Staging, Production
6. **Document Custom Configs:** Add comments in a separate file

---

## 📖 Related Documentation

- [Main README](../README.md) - Installation and usage
- [Enhanced Notifications](../docs/ENHANCED_NOTIFICATIONS.md) - Notification features
- [Docker Integration](../docs/README.md) - Auto-discovery details

---

**Need Help?** Open an issue on GitHub with your config file (remove sensitive data first!)
