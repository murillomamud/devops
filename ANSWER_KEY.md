# 📋 Gabarito de Correções - Staff DevOps Challenge

Este documento lista todas as correções que o candidato deveria ter implementado.

---

## 🎯 Problemas Identificados e Correções

### ❌ Problema 1: DB_HOST Incorreto
**Arquivo**: `helm/staff-app/templates/api-deployment.yaml`

**Antes:**
```yaml
env:
  - name: DB_HOST
    value: postgres-service  # ❌ Service não existe
```

**Depois:**
```yaml
env:
  - name: DB_HOST
    value: postgres  # ✅ Nome correto do service
```

**Impacto**: API não conseguia conectar ao PostgreSQL (erro 500 no `/db`)

---

### ❌ Problema 2: Número Incorreto de Réplicas
**Arquivo**: `helm/staff-app/values.yaml`

**Antes:**
```yaml
replicaCount: 1  # ❌ Requisito é 2 réplicas
```

**Depois:**
```yaml
replicaCount: 2  # ✅ Conforme requisito
```

**Impacto**: Alta disponibilidade comprometida, não atende requisito mínimo

---

### ❌ Problema 3: Porta do Prometheus Incorreta
**Arquivo**: `helm/staff-app/values.yaml`

**Antes:**
```yaml
prometheus:
  scrapePort: 9999  # ❌ API expõe métricas na 9464
```

**Depois:**
```yaml
prometheus:
  scrapePort: 9464  # ✅ Porta correta
```

**Impacto**: Prometheus não consegue coletar métricas da API

---

### ❌ Problema 4: Credenciais em Texto Puro
**Arquivos**: 
- `helm/staff-app/templates/api-deployment.yaml`
- `helm/staff-app/templates/db-deployment.yaml` (ou `db-statefulset.yaml`)

**Criar novo arquivo**: `helm/staff-app/templates/db-secret.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
stringData:
  POSTGRES_USER: {{ .Values.database.user }}
  POSTGRES_PASSWORD: {{ .Values.database.password }}
  POSTGRES_DB: {{ .Values.database.name }}
```

**Atualizar api-deployment.yaml:**

**Antes:**
```yaml
env:
  - name: DB_USER
    value: {{ .Values.database.user }}  # ❌ Texto puro
  - name: DB_PASSWORD
    value: {{ .Values.database.password }}  # ❌ Exposto
```

**Depois:**
```yaml
env:
  - name: DB_USER
    valueFrom:
      secretKeyRef:
        name: postgres-secret
        key: POSTGRES_USER
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: postgres-secret
        key: POSTGRES_PASSWORD
  - name: DB_NAME
    valueFrom:
      secretKeyRef:
        name: postgres-secret
        key: POSTGRES_DB
```

**Impacto**: Vulnerabilidade de segurança crítica

---

### ❌ Problema 5: Falta de Health Checks
**Arquivo**: `helm/staff-app/templates/api-deployment.yaml`

**Adicionar após `ports:`**:

```yaml
ports:
  - containerPort: 3000
  - containerPort: 9464
readinessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 15
  periodSeconds: 20
  timeoutSeconds: 5
  failureThreshold: 3
```

**Impacto**: Rolling updates podem causar downtime, pods com falha recebem tráfego

---

### ❌ Problema 6: PostgreSQL sem Persistência
**Solução 1: Converter para StatefulSet** (⭐ RECOMENDADO)

**Criar novo arquivo**: `helm/staff-app/templates/db-statefulset.yaml`

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:15
          env:
            - name: POSTGRES_USER
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: POSTGRES_USER
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: POSTGRES_PASSWORD
            - name: POSTGRES_DB
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: POSTGRES_DB
            - name: PGDATA
              value: /var/lib/postgresql/data/pgdata
          ports:
            - containerPort: 5432
              name: postgres
          volumeMounts:
            - name: postgres-storage
              mountPath: /var/lib/postgresql/data
          readinessProbe:
            exec:
              command:
                - pg_isready
                - -U
                - $(POSTGRES_USER)
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            exec:
              command:
                - pg_isready
                - -U
                - $(POSTGRES_USER)
            initialDelaySeconds: 30
            periodSeconds: 10
  volumeClaimTemplates:
    - metadata:
        name: postgres-storage
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
```

**Atualizar**: `helm/staff-app/templates/db-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  clusterIP: None  # ✅ Headless service para StatefulSet
  selector:
    app: postgres
  ports:
    - port: 5432
      targetPort: 5432
```

**Solução 2: Mínima (adicionar PVC ao Deployment)**

Se o candidato manteve Deployment, pelo menos deveria ter adicionado um PVC:

```yaml
# Adicionar volumes e volumeMounts
volumes:
  - name: postgres-storage
    persistentVolumeClaim:
      claimName: postgres-pvc
```

**Impacto**: Perda de dados ao reiniciar pod, não é production-ready

---

## 🏆 Pontos Extras (Bonus)

### 1. Security Context
```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
```

### 2. Resource Limits
```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "500m"
```

### 3. Anti-Affinity (para réplicas da API)
```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - api
          topologyKey: kubernetes.io/hostname
```

### 4. HPA (Horizontal Pod Autoscaler)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

---

## 📊 Critérios de Avaliação

### Mínimo Esperado (70%)
- ✅ DB_HOST corrigido
- ✅ 2 réplicas da API
- ✅ Porta do Prometheus correta
- ✅ Secrets implementados
- ✅ Health checks básicos

### Bom (85%)
Mínimo + 
- ✅ StatefulSet para PostgreSQL
- ✅ PVC implementado
- ✅ Health probes no PostgreSQL

### Excelente (95%+)
Bom + 
- ✅ Security context
- ✅ Resource limits
- ✅ Documentação clara das decisões
- ✅ Considerações sobre trade-offs

---

## 🗣️ Questões para Discussão

Durante a avaliação, pergunte:

### Arquitetura
1. Por que você escolheu StatefulSet vs Deployment para o PostgreSQL?
2. Como você garantiria backup e disaster recovery do banco?
3. O que acontece durante um rolling update da API?

### Segurança
4. Como você gerenciaria secrets em produção real? (Vault, External Secrets, AWS Secrets Manager?)
5. Por que não rodar containers como root?
6. Como você implementaria network policies?

### Escalabilidade
7. A API deveria usar HPA? Baseado em que métrica?
8. Como você lidaria com 20 times usando este chart?
9. Que recursos compartilhados poderiam causar problemas? (noisy neighbor)

### Observabilidade
10. Como você estenderia para incluir tracing distribuído?
11. Que SLIs/SLOs você definiria para esta API?
12. Onde você configuraria alertas? (Prometheus Alertmanager, PagerDuty?)

---

## 🎯 Red Flags

Desqualificar se:
- ❌ Não conseguiu fazer a API conectar ao banco
- ❌ Não implementou nenhuma correção de segurança
- ❌ Não entende conceitos básicos de Kubernetes
- ❌ Não consegue explicar suas decisões

## ✅ Green Flags

Contratar se:
- ✅ Implementou todas as correções básicas
- ✅ Demonstra thinking at scale
- ✅ Considera trade-offs (ex: StatefulSet vs managed DB)
- ✅ Propõe melhorias além do solicitado
- ✅ Documenta decisões arquiteturais

---

## 📝 Exemplo de Resposta Esperada

Um bom candidato deveria:

1. **Identificar os problemas** rapidamente analisando logs e manifests
2. **Priorizar** as correções (DB_HOST primeiro, depois segurança)
3. **Implementar** soluções production-grade (StatefulSet, Secrets)
4. **Testar** cada correção individualmente
5. **Documentar** suas decisões e trade-offs
6. **Discutir** melhorias futuras (managed PostgreSQL, service mesh, etc.)

---

## 🚀 Como Aplicar as Correções

```bash
# 1. Fazer as correções nos arquivos
# 2. Se criou StatefulSet, deletar o deployment antigo
kubectl delete deployment postgres

# 3. Upgrade do Helm chart
helm upgrade staff ./helm/staff-app

# 4. Validar
./test.sh

# 5. Testar endpoints
kubectl exec -it $(kubectl get pod -l app=api -o jsonpath='{.items[0].metadata.name}') -- wget -qO- http://localhost:3000/db
```

---
