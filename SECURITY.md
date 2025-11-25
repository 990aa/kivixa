# Security Policy

## Supported Versions

We release security patches for the following versions of Kivixa:

| Version | Supported          |
| ------- | ------------------ |
| 0.0.x   | :white_check_mark: |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please follow these guidelines:

### How to Report

1. **Do NOT** create a public GitHub issue for security vulnerabilities
2. Email the security concern directly to the maintainers via GitHub's private vulnerability reporting feature
3. Alternatively, open a private security advisory at: [GitHub Security Advisories](https://github.com/990aa/kivixa/security/advisories/new)

### What to Include

When reporting a vulnerability, please include:

- **Description** - A clear description of the vulnerability
- **Steps to Reproduce** - Detailed steps to reproduce the issue
- **Impact** - Potential impact and severity of the vulnerability
- **Environment** - Operating system, app version, and any relevant configuration
- **Proof of Concept** - If applicable, include code or screenshots

### Response Timeline

- **Initial Response**: Within 48 hours of report submission
- **Status Update**: Within 7 days with an assessment of the vulnerability
- **Resolution**: Security patches are prioritized and typically released within 30 days for critical issues

### What to Expect

1. **Acknowledgment** - We'll confirm receipt of your report
2. **Investigation** - Our team will investigate and validate the vulnerability
3. **Communication** - We'll keep you informed about the progress
4. **Credit** - With your permission, we'll acknowledge your contribution in our release notes

## Security Best Practices

### For Users

- **Keep Updated** - Always use the latest version of Kivixa
- **Device Security** - Ensure your device has proper security measures (screen lock, encryption)
- **Data Backups** - Regularly backup your notes and data
- **Source Verification** - Only download Kivixa from official sources (GitHub releases, official app stores)

### Data Privacy

Kivixa is designed with privacy in mind:

- **Local-First Architecture** - All data is stored locally on your device
- **No Telemetry** - We don't collect usage data or analytics
- **No Account Required** - Use the app without creating an account
- **Secure Storage** - Sensitive data is encrypted using `flutter_secure_storage`
- **Offline Capable** - Full functionality without internet connection

### Known Security Considerations

- **File Permissions** - The app requires file system access to save and load notes
- **Export Data** - Exported files are not encrypted; handle them according to your security needs
- **Shared Devices** - On shared devices, consider the visibility of your notes

## Security Updates

Security updates are released as patch versions (e.g., 0.0.1 → 0.0.2). We recommend:

- Enabling automatic updates when available
- Subscribing to repository releases for notifications
- Checking the [CHANGELOG](CHANGELOG.md) for security-related updates

## Contact

For security-related inquiries that don't involve vulnerability reports:

- **GitHub Issues** - For general security questions or suggestions
- **GitHub Discussions** - For community security discussions

---

Thank you for helping keep Kivixa secure!
