# 📋 Issue Templates

## 🎯 **Available Templates**

### **🐞 Bug Report** (`bug_report.yml`)

Use this template when you encounter a bug or unexpected behavior in any of the automas scripts.

**Key Features:**

- Script selection dropdown (Aetherix, Sato, f-create, etc.)
- Version/command specification
- Structured reproduction steps
- Environment information collection
- Log and error capture

### **✨ Feature Request** (`feature_request.yml`)

Use this template to suggest new features or enhancements.

**Key Features:**

- Script selection dropdown
- Problem/use case description
- Proposed solution format
- Priority indication
- Implementation willingness checkbox

## 🛠️ **How to Use**

### **Creating a Bug Report**

1. Go to Issues → New Issue
2. Select "🐞 Bug Report"
3. Fill in all required fields:
   - Which script has the issue
   - Version or command used
   - Bug description
   - Reproduction steps
   - Expected vs actual behavior
   - Environment details

### **Creating a Feature Request**

1. Go to Issues → New Issue
2. Select "✨ Feature Request"
3. Fill in all required fields:
   - Which script to enhance
   - Feature description
   - Problem it solves
   - Proposed solution
   - Priority level

## 📚 **Template Structure**

### **Bug Report Fields**

1. **Script Selection** - Dropdown with all automas scripts
2. **Version/Command** - Specific command or version used
3. **Bug Description** - Clear description of the issue
4. **Reproduction Steps** - How to reproduce the bug
5. **Expected vs Actual** - What should happen vs what happened
6. **Logs/Errors** - Error messages and stack traces
7. **Environment** - OS, shell, versions
8. **Configuration** - Script-specific settings
9. **Additional Context** - Screenshots, extra details
10. **Checklist** - Pre-submission verification

### **Feature Request Fields**

1. **Script Selection** - Which script to enhance
2. **Feature Description** - What you want
3. **Problem/Use Case** - Why you need it
4. **Proposed Solution** - How it could work
5. **Alternatives** - Other solutions considered
6. **Priority** - How important it is
7. **Additional Context** - Extra details
8. **Checklist** - Duplicate check, implementation willingness

## 🎨 **Customization**

### **Adding New Scripts**

When you add a new script to automas, update both templates:

```yaml
# In bug_report.yml and feature_request.yml
options:
  - Your New Script Name
  - Aetherix/Alchemy (Environment Setup)
  - ...
```

### **Modifying Fields**

Edit the `.yml` files to add/remove fields as needed. GitHub will automatically update the issue forms.

## 💡 **Best Practices**

### **For Bug Reports**

- Be specific about which script and version
- Include exact commands used
- Provide complete error messages
- Share relevant configuration
- Test with `--debug` flag if available

### **For Feature Requests**

- Explain the problem, not just the solution
- Consider existing features and workarounds
- Be realistic about priority
- Offer to help implement if possible

## 🔗 **Related Files**

- **`config.yml`** - Issue template configuration
- **`../PULL_REQUEST_TEMPLATE.md`** - PR template
- **`../../CONTRIBUTING.md`** - Contribution guidelines (if exists)

---

**These templates help maintain high-quality issues and make it easier for contributors to help! 🎯**
