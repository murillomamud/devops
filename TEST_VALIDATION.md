# 🧪 Script de Validação - Staff DevOps Challenge

### 1️⃣ Requisitos Mínimos (Obrigatórios)
- ✅ Helm chart instalado no cluster
- ✅ 2 réplicas da API rodando
- ✅ 1 réplica do PostgreSQL
- ✅ Pods prontos e saudáveis

### 2️⃣ Conectividade e Funcionalidade
- ✅ Endpoint `/health` da API funcionando
- ✅ Endpoint `/db` conectando ao PostgreSQL

### 3️⃣ Segurança
- ✅ Kubernetes Secret criado para credenciais
- ✅ API usando `secretKeyRef` (não texto puro)
- ✅ PostgreSQL usando `secretKeyRef`

### 4️⃣ Health Checks
- ✅ Readiness Probe configurado
- ✅ Liveness Probe configurado
- ✅ Probes funcionando corretamente

### 5️⃣ Persistência de Dados
- ✅ PersistentVolumeClaim criado
- ✅ Health probes no PostgreSQL (`pg_isready`)

### 6️⃣ Observabilidade
- ✅ Prometheus rodando
- ✅ Porta de scrape correta