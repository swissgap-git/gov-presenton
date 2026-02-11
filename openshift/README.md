# Red Hat OpenShift Deployment Guide for Presenton

## 📋 Overview

This guide provides comprehensive instructions for deploying Presenton on Red Hat OpenShift Platform (RHOS). All configurations have been optimized for OpenShift security requirements and best practices.

## 🏗️ Architecture

### OpenShift-Specific Components
- **BuildConfig**: Automated builds from Git repository
- **ImageStream**: Container image management
- **Routes**: OpenShift-native routing (replaces Ingress)
- **Security Contexts**: Enhanced security for OpenShift
- **Storage Classes**: RHOS-optimized storage

## 🚀 Quick Deployment

### Prerequisites
- OpenShift 4.x cluster
- `oc` CLI tool configured
- Project/namespace permissions
- Container registry access

### Step 1: Create Project
```bash
oc new-project presenton
oc project presenton
```

### Step 2: Apply All Configurations
```bash
# Apply all OpenShift configurations
oc apply -f openshift/

# Or apply step by step:
oc apply -f openshift/storage.yaml
oc apply -f openshift/service.yaml
oc apply -f openshift/deployment.yaml
oc apply -f openshift/route.yaml
oc apply -f openshift/buildconfig.yaml
```

### Step 3: Configure Secrets
```bash
# Create secrets for API keys and configurations
oc create secret generic presenton-secrets \
  --from-literal=session-secret-key="your-32-character-secret-key-minimum" \
  --from-literal=llm="openai" \
  --from-literal=openai-api-key="your-openai-api-key" \
  --from-literal=google-api-key="your-google-api-key" \
  --from-literal=pexels-api-key="your-pexels-api-key" \
  --from-literal=ollama-model="llama3.2:3b"
```

### Step 4: Start Build
```bash
# Trigger build from Git repository
oc start-build presenton-build --follow
```

### Step 5: Verify Deployment
```bash
# Check pod status
oc get pods

# Check routes
oc get routes

# Check build status
oc get builds
```

## 🔧 Configuration Details

### Security Enhancements

#### Dockerfile.rhos
- **Base Image**: Red Hat UBI 9 with Python 3.11
- **User Management**: Non-root user (UID 1001)
- **Package Management**: DNF with minimal dependencies
- **Health Check**: Built-in container health monitoring

#### Security Contexts
```yaml
securityContext:
  runAsNonRoot: true
  fsGroup: 1001
  seccompProfile:
    type: RuntimeDefault
```

#### Container Security
```yaml
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
    - ALL
```

### Resource Optimization

#### CPU and Memory
```yaml
resources:
  requests:
    memory: "1Gi"      # Optimized from 2Gi
    cpu: "500m"         # Optimized from 1000m
  limits:
    memory: "2Gi"       # Optimized from 4Gi
    cpu: "1000m"        # Optimized from 2000m
```

### Storage Configuration

#### RHOS Storage Classes
- **Primary Storage**: `gp3-csi` (20Gi for user data)
- **Temp Storage**: `gp3-csi` (5Gi for temporary files)
- **Access Modes**: ReadWriteOnce and ReadWriteMany

### Networking

#### OpenShift Routes
- **Main Route**: HTTPS with edge termination
- **API Route**: Separate route for API endpoints
- **TLS**: Automatic SSL certificate management

## 🔄 CI/CD Integration

### BuildConfig Features
- **Source**: Git repository integration
- **Strategy**: Docker build with custom Dockerfile.rhos
- **Triggers**: GitHub webhooks, config changes, image changes
- **Resources**: Optimized build resource limits

### Automated Deployment
```bash
# Set up GitHub webhook
oc set build-secret --source/buildconfig \
  presenton-build webhook-secret

# Trigger automatic builds on git push
# (Configure webhook in GitHub repository)
```

## 📊 Monitoring and Troubleshooting

### Health Checks
- **Liveness Probe**: Every 10 seconds after 30s delay
- **Readiness Probe**: Every 5 seconds after 5s delay
- **Health Endpoint**: `/health` path

### Logs and Debugging
```bash
# View application logs
oc logs -f deployment/presenton

# View build logs
oc logs -f buildconfig/presenton-build

# Debug pod issues
oc rsh <pod-name>
oc describe pod <pod-name>
```

### Common Issues

#### Build Failures
```bash
# Check build status
oc get builds

# View build logs
oc logs build/<build-name>

# Restart build
oc start-build presenton-build --follow
```

#### Pod Issues
```bash
# Check pod events
oc describe pod <pod-name>

# Check resource usage
oc top pods

# Scale deployment
oc scale deployment presenton --replicas=3
```

## 🔐 Security Considerations

### OpenShift Security Policies
- **SCC Compliance**: Uses anyuid SCC for non-root containers
- **SELinux**: Proper context labeling
- **Capabilities**: All capabilities dropped
- **Filesystem**: Read-only root filesystem

### Network Policies
```yaml
# Example network policy (optional)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: presenton-netpol
spec:
  podSelector:
    matchLabels:
      app: presenton
  policyTypes:
  - Ingress
  - Egress
```

## 🚀 Production Deployment

### Scaling
```bash
# Horizontal scaling
oc scale deployment presenton --replicas=5

# Enable autoscaling
oc autoscale deployment presenton \
  --min=2 --max=10 --cpu-percent=70
```

### Backup and Recovery
```bash
# Backup persistent data
oc exec <pod-name> -- tar czf - /app/user_data > backup.tar.gz

# Restore data
oc exec <pod-name> -- tar xzf - -C /app/user_data < backup.tar.gz
```

### Updates and Maintenance
```bash
# Update application
oc start-build presenton-build --follow

# Rolling update
oc set image deployment/presenton \
  presenton=presenton:new-version

# Rollback
oc rollout undo deployment/presenton
```

## 📚 Additional Resources

- [OpenShift Documentation](https://docs.openshift.com/)
- [Red Hat UBI Documentation](https://access.redhat.com/documentation/en-us/red_hat_universal_base_image/)
- [OpenShift Security](https://docs.openshift.com/container-platform/4.11/security/index.html)

## 🆘 Support

For issues specific to this OpenShift deployment:
1. Check the troubleshooting section above
2. Review OpenShift cluster logs
3. Verify RBAC permissions
4. Contact your OpenShift administrator

---

**Note**: This deployment configuration assumes you have the necessary permissions in your OpenShift cluster. Adjust resource limits and storage sizes based on your specific requirements and cluster capacity.
