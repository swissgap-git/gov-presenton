# Kubernetes Deployment Guide für Presenton

## 📋 Was wird benötigt?

### 1. Container-Image (Docker Image)
- Ja, du benötigst ein Docker-Image
- Das Image wird in einer Registry gespeichert (Docker Hub, GitHub Registry, etc.)
- Kubernetes lädt das Image von dort

### 2. Kubernetes Manifeste
- Deployment.yaml (Pod-Definition)
- Service.yaml (Netzwerk-Exposure)
- ConfigMap.yaml (Konfiguration)
- Secret.yaml (Passwörter/API-Keys)

## 🐳 Image Erstellung & Push

### Option 1: Docker Hub
```bash
# Image bauen
docker build -t dein-username/presenton:latest .

# Einloggen
docker login

# Push zu Docker Hub
docker push dein-username/presenton:latest
```

### Option 2: GitHub Container Registry
```bash
# Image taggen
docker tag presenton:latest ghcr.io/dein-username/presenton:latest

# Einloggen bei GitHub
echo $GITHUB_TOKEN | docker login ghcr.io -u dein-username --password-stdin

# Push zu GHCR
docker push ghcr.io/dein-username/presenton:latest
```

## ☸️ Kubernetes Deployment

### 1. Namespace erstellen
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: presenton
```

### 2. Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: presenton
  namespace: presenton
spec:
  replicas: 2
  selector:
    matchLabels:
      app: presenton
  template:
    metadata:
      labels:
        app: presenton
    spec:
      containers:
      - name: presenton
        image: dein-username/presenton:latest
        ports:
        - containerPort: 5000
        env:
        - name: NODE_ENV
          value: "production"
        - name: CAN_CHANGE_KEYS
          value: "false"
```

### 3. Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: presenton-service
  namespace: presenton
spec:
  selector:
    app: presenton
  ports:
  - port: 80
    targetPort: 5000
  type: LoadBalancer
```

## 🚀 Deployment Prozess

### Schritt 1: Image Build & Push
```bash
# Lokal entwickeln
docker build -t dein-username/presenton:v1.0.0 .

# Push zu Registry
docker push dein-username/presenton:v1.0.0
```

### Schritt 2: Kubernetes Deploy
```bash
# Manifeste anwenden
kubectl apply -f namespace.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Status prüfen
kubectl get pods -n presenton
kubectl get services -n presenton
```

## 🔧 CI/CD Pipeline (GitHub Actions)

```yaml
name: Deploy to Kubernetes
on:
  push:
    tags: ['v*']

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Build Docker image
      run: docker build -t ghcr.io/${{ github.repository }}:${{ github.ref_name }} .
    
    - name: Login to GHCR
      run: echo ${{ secrets.GITHUB_TOKEN }} | docker login ghcr.io -u ${{ github.actor }} --password-stdin
    
    - name: Push to GHCR
      run: docker push ghcr.io/${{ github.repository }}:${{ github.ref_name }}
    
    - name: Deploy to Kubernetes
      run: |
        sed -i "s|IMAGE_TAG|ghcr.io/${{ github.repository }}:${{ github.ref_name }}|" deployment.yaml
        kubectl apply -f deployment.yaml
```

## 📊 Monitoring

### Health Checks im Deployment
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 5000
  initialDelaySeconds: 5
  periodSeconds: 5
```

## 🔐 Secrets Management

```bash
# Secret erstellen
kubectl create secret generic presenton-secrets \
  --from-literal=OPENAI_API_KEY="dein-key" \
  --from-literal=SESSION_SECRET_KEY="dein-secret" \
  -n presenton
```

## 🌐 Ingress (Optional)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: presenton-ingress
  namespace: presenton
spec:
  rules:
  - host: presenton.deine-domain.de
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: presenton-service
            port:
              number: 80
```

## 📝 Zusammenfassung

1. **Ja, Image ist erforderlich** - Docker Image wird gebuildet und gepusht
2. **Registry** - Docker Hub, GHCR, oder private Registry
3. **Manifeste** - YAML-Dateien für Kubernetes Ressourcen
4. **Deployment** - `kubectl apply` oder CI/CD Pipeline
5. **Monitoring** - Health Checks, Logs, Metrics

## 🔄 Update Prozess

```bash
# Neue Version
docker build -t dein-username/presenton:v1.1.0 .
docker push dein-username/presenton:v1.1.0

# Kubernetes Update
sed -i 's|dein-username/presenton:v1.0.0|dein-username/presenton:v1.1.0|' deployment.yaml
kubectl apply -f deployment.yaml
```
