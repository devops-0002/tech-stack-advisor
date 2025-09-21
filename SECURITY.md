# Security Policy

## Vulnerability Scanning

This project uses automated security scanning as part of our CI/CD pipeline to ensure container images are free from known vulnerabilities.

### Scanning Tools

- **Trivy**: Primary vulnerability scanner for container images
- **SBOM Generation**: Software Bill of Materials for supply chain transparency
- **GitHub Security**: Integration with GitHub's security features

### Security Gates

Our CI pipeline implements the following security gates:

| Severity | Action |
|----------|--------|
| CRITICAL | ❌ **Block deployment** - Build fails immediately |
| HIGH | ⚠️ **Warning** - Logged but build continues if < 5 vulnerabilities |
| MEDIUM/LOW | ✅ **Allow** - Logged for monitoring |

### Security Artifacts

Each build generates:

1. **SARIF Report** - Uploaded to GitHub Security tab
2. **Human-readable Report** - Stored as build artifact
3. **SBOM (SPDX)** - Software Bill of Materials
4. **Vulnerability Database** - Updated regularly

### Customizing Security Thresholds

To modify security gates, update the CI workflow:

```yaml
# Example: Block on 3+ HIGH vulnerabilities instead of 5
- name: Security gate - Warn on HIGH vulnerabilities
  if: steps.vuln-check.outputs.high-count > 3
```

### Vulnerability Management

1. **Critical/High Issues**: Must be addressed before deployment
2. **Medium Issues**: Addressed in next sprint
3. **Low Issues**: Monitored and addressed during maintenance windows

### Reporting Security Issues

If you discover a security vulnerability, please report it to:
- Email: security@yourcompany.com
- Create a private security advisory on GitHub

### Updates and Maintenance

- Vulnerability database updated daily
- Security policies reviewed quarterly
- SBOM generated for every release

## Supply Chain Security

### SBOM (Software Bill of Materials)

Every container image includes:
- All installed packages and versions
- Dependency relationships
- License information
- Source repositories

### Image Signing

Consider implementing image signing for production deployments:

```bash
# Example with Cosign
cosign sign --key cosign.key $IMAGE_TAG
```

### Base Image Security

- Use minimal base images (python:3.11-slim)
- Regular base image updates
- Non-root container execution
- Read-only root filesystem when possible
