# 🧪 Script de Validação - Staff DevOps Challenge

Este script automatiza a validação de todas as correções necessárias no desafio.

## 📋 O que o script valida

### 1️⃣ Requisitos Mínimos (Obrigatórios)
- ✅ Helm chart instalado no cluster
- ✅ 2 réplicas da API rodando
- ✅ 1 réplica do PostgreSQL
- ✅ Pods prontos e saudáveis

### 2️⃣ Conectividade e Funcionalidade
- ✅ Endpoint `/health` da API funcionando
- ✅ Endpoint `/db` conectando ao PostgreSQL
- ✅ Service `postgres` existe
- ✅ `DB_HOST` configurado corretamente

### 3️⃣ Segurança
- ✅ Kubernetes Secret criado para credenciais
- ✅ API usando `secretKeyRef` (não texto puro)
- ✅ PostgreSQL usando `secretKeyRef`
- ⚠️ Aviso se `values.yaml` ainda expõe senhas

### 4️⃣ Health Checks
- ✅ Readiness Probe configurado
- ✅ Liveness Probe configurado
- ✅ Probes funcionando corretamente

### 5️⃣ Persistência de Dados
- ✅ PostgreSQL como StatefulSet (vs Deployment)
- ✅ PersistentVolumeClaim criado
- ✅ PVC em estado "Bound"
- ✅ Health probes no PostgreSQL (`pg_isready`)

### 6️⃣ Observabilidade
- ✅ Prometheus rodando
- ✅ Porta de scrape correta (9464)
- ✅ API expondo métricas

### 7️⃣ Boas Práticas (Bonus)
- 💡 Security context (`runAsNonRoot`)
- 💡 Resource limits configurados
- 💡 Labels consistentes

## 🚀 Como usar

### Executar os testes:
```bash
./test.sh
```

### Visualizar apenas erros:
```bash
./test.sh | grep -E "FALHOU|AVISO"
```

### Salvar resultado em arquivo:
```bash
./test.sh > validation-results.txt
```

## 📊 Sistema de Pontuação

O script calcula automaticamente a pontuação:

- **90-100%**: 🎉 EXCELENTE! (exit code 0)
- **70-89%**: ⚠️ BOM, mas precisa melhorias (exit code 1)
- **0-69%**: ❌ INSUFICIENTE (exit code 2)

## 🎯 Correções Esperadas

O candidato deve ter corrigido:

1. **DB_HOST**: `postgres-service` → `postgres`
2. **Réplicas da API**: `1` → `2`
3. **Porta do Prometheus**: `9999` → `9464`
4. **Segurança**: Credentials em texto puro → Kubernetes Secrets
5. **Health Checks**: Adicionar readiness/liveness probes
6. **PostgreSQL**: Deployment → StatefulSet com PVC

## 🔍 Interpretando os Resultados

### Saída de Exemplo:

```
✅ PASSOU: API tem 2 réplicas configuradas
❌ FALHOU: PostgreSQL deve usar secretKeyRef para credenciais
   Motivo: Não use 'value:' direto
⚠️  AVISO: PostgreSQL deveria ter readiness probe com pg_isready
ℹ️  INFO: Bonus: Configure securityContext.runAsNonRoot: true
```

- **✅ PASSOU**: Requisito atendido corretamente
- **❌ FALHOU**: Requisito obrigatório não atendido
- **⚠️ AVISO**: Recomendação não seguida
- **ℹ️ INFO**: Sugestão de melhoria (bonus)

## 💡 Para Avaliadores

Este script verifica tanto os **requisitos mínimos** quanto as **best practices** esperadas de um Staff Engineer:

- Conhecimento profundo de Kubernetes
- Segurança (Secrets, não root)
- Observabilidade (métricas, probes)
- Persistência de dados
- Thinking at scale (StatefulSet, PVCs)

## 🛠️ Troubleshooting

### Script não encontra pods:
```bash
kubectl get pods
# Verifique se os pods estão rodando
```

### Erro de permissão:
```bash
chmod +x test.sh
```

### Testar conexão manualmente:
```bash
kubectl exec -it $(kubectl get pod -l app=api -o jsonpath='{.items[0].metadata.name}') -- wget -qO- http://localhost:3000/health
```

## 📚 Referências

- [Kubernetes Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Secrets Management](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
