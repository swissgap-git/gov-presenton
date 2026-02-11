# Presenton Kubernetes Deployment

This directory contains Kubernetes manifests for deploying Presenton on-premises with security best practices.

## Prerequisites

- Kubernetes cluster (v1.20+)
- kubectl configured
- Ingress controller (nginx recommended)
- Persistent storage provisioner

## Security Features

- **Non-root execution**: Container runs as user ID 1000
- **Pod Security Policy**: Restricts privileged operations
- **Security Context**: Drops all capabilities, prevents privilege escalation
- **Secrets Management**: API keys stored in Kubernetes secrets
- **Resource Limits**: Memory and CPU constraints applied

## Deployment Steps

### 1. Create Namespace (Optional)
```bash
kubectl create namespace presenton
kubectl config set-context --current --namespace=presenton
```

### 2. Configure Secrets
Edit `k8s/secrets.yaml` with your actual API keys:
```yaml
stringData:
  llm: "openai"  # openai, google, or ollama
  openai-api-key: "your-actual-key"
  google-api-key: "your-actual-key"
  ollama-model: "llama3.2:3b"
  pexels-api-key: "your-actual-key"
```

### 3. Apply Manifests
```bash
# Apply secrets first
kubectl apply -f k8s/secrets.yaml

# Apply storage and service
kubectl apply -f k8s/service.yaml

# Apply deployment
kubectl apply -f k8s/deployment.yaml

# Apply ingress (optional)
kubectl apply -f k8s/ingress.yaml

# Apply Pod Security Policy (if enabled in cluster)
kubectl apply -f k8s/pod-security-policy.yaml
```

### 4. Verify Deployment
```bash
kubectl get pods
kubectl logs deployment/presenton
kubectl get ingress presenton-ingress
```

## Configuration

### Environment Variables
- `APP_DATA_DIRECTORY`: User data storage location
- `TEMP_DIRECTORY`: Temporary files location
- `CAN_CHANGE_KEYS`: Allow UI-based key changes
- `NODE_ENV`: Set to "production"
- `LLM`: AI provider (openai/google/ollama)

### Resource Requirements
- **Memory**: 2Gi request, 4Gi limit
- **CPU**: 1000m request, 2000m limit
- **Storage**: 10Gi persistent volume

### Access Options
1. **Port Forward**: `kubectl port-forward service/presenton-service 8080:80`
2. **Ingress**: Configure DNS for `presenton.local`
3. **LoadBalancer**: Change service type if using cloud provider

## Security Considerations

1. **Network Policies**: Consider adding network policies to restrict traffic
2. **RBAC**: Implement role-based access control
3. **Image Security**: Use signed images and vulnerability scanning
4. **Secrets Rotation**: Implement regular API key rotation

## Troubleshooting

### Permission Issues
If you encounter permission errors, ensure:
- Persistent volume has correct permissions
- Security context matches container user (1000:1000)

### Ollama Models
For Ollama deployments:
- Ensure sufficient GPU resources if using acceleration
- Models are pulled during first startup
- Check logs for model download progress

### Storage Issues
- Verify storage class availability
- Check PVC status: `kubectl get pvc`
- Ensure sufficient disk space

## Production Recommendations

1. **Monitoring**: Add Prometheus metrics and Grafana dashboards
2. **Logging**: Implement centralized logging (ELK stack)
3. **Backup**: Regular backups of user data PVC
4. **Updates**: Use rolling updates for zero-downtime deployments
5. **Scaling**: Consider horizontal pod autoscaling for high availability
