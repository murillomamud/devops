#!/bin/bash

# Script de Validação - Staff DevOps Challenge
# Este script valida se todas as correções foram implementadas corretamente

# Removido 'set -e' para continuar mesmo com erros

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 TESTE DE VALIDAÇÃO - STAFF DEVOPS CHALLENGE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para teste
test_passed() {
    echo -e "${GREEN}✅ PASSOU:${NC} $1"
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
}

test_failed() {
    echo -e "${RED}❌ FALHOU:${NC} $1"
    echo -e "${YELLOW}   Motivo: $2${NC}"
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
}

test_warning() {
    echo -e "${YELLOW}⚠️  AVISO:${NC} $1"
}

test_info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 TESTE 1: Verificando Requisitos Mínimos"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1.1 - Verificar se o Helm chart está instalado
if helm list | grep -q "staff"; then
    test_passed "Helm chart 'staff' está instalado"
else
    test_failed "Helm chart 'staff' não está instalado" "Execute: helm install staff ./helm/staff-app"
fi

# 1.2 - Verificar número de réplicas da API
API_REPLICAS=$(kubectl get deployment api -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
if [ "$API_REPLICAS" -eq 2 ]; then
    test_passed "API tem 2 réplicas configuradas"
else
    test_failed "API deve ter 2 réplicas" "Atual: $API_REPLICAS réplicas"
fi

# 1.3 - Verificar se as réplicas da API estão prontas
API_READY=$(kubectl get deployment api -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
if [ "$API_READY" -eq 2 ]; then
    test_passed "2 réplicas da API estão prontas e rodando"
else
    test_failed "2 réplicas da API devem estar prontas" "Atual: $API_READY réplicas prontas"
fi

# 1.4 - Verificar PostgreSQL
PG_PODS=$(kubectl get pods -l app=postgres --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [ "$PG_PODS" -eq 1 ]; then
    test_passed "1 réplica do PostgreSQL está rodando"
else
    test_failed "Deve haver exatamente 1 réplica do PostgreSQL" "Encontrado: $PG_PODS pods"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔗 TESTE 2: Conectividade e Funcionalidade"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 2.1 - Testar endpoint /health da API
API_POD=$(kubectl get pod -l app=api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$API_POD" ]; then
    HEALTH_RESPONSE=$(kubectl exec -it $API_POD -- wget -qO- http://localhost:3000/health 2>/dev/null || echo "FAILED")
    if [ "$HEALTH_RESPONSE" = "OK" ]; then
        test_passed "Endpoint /health da API responde corretamente"
    else
        test_failed "Endpoint /health não está funcionando" "Resposta: $HEALTH_RESPONSE"
    fi
else
    test_failed "Não foi possível encontrar pod da API" "Verifique se os pods estão rodando"
fi

# 2.2 - Testar conexão com banco de dados
if [ -n "$API_POD" ]; then
    DB_RESPONSE=$(kubectl exec -it $API_POD -- wget -qO- http://localhost:3000/db 2>/dev/null || echo "FAILED")
    if [[ "$DB_RESPONSE" == *"now"* ]]; then
        test_passed "API consegue conectar ao PostgreSQL e retornar dados"
    else
        test_failed "API não consegue conectar ao PostgreSQL" "Verifique DB_HOST e credenciais"
    fi
fi

# 2.3 - Verificar se o serviço postgres existe e está correto
if kubectl get service postgres &>/dev/null; then
    test_passed "Service 'postgres' existe"
    
    # Verificar DB_HOST no deployment
    DB_HOST=$(kubectl get deployment api -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="DB_HOST")].value}' 2>/dev/null)
    if [ "$DB_HOST" = "postgres" ]; then
        test_passed "DB_HOST configurado corretamente como 'postgres'"
    else
        test_failed "DB_HOST deve ser 'postgres'" "Atual: $DB_HOST"
    fi
else
    test_failed "Service 'postgres' não existe" "Crie o service do PostgreSQL"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 TESTE 3: Segurança (Secrets)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 3.1 - Verificar se Secret foi criado
if kubectl get secret postgres-secret &>/dev/null; then
    test_passed "Secret 'postgres-secret' foi criado"
else
    test_failed "Secret 'postgres-secret' não existe" "Credenciais devem estar em Secrets, não em texto puro"
fi

# 3.2 - Verificar se API usa secretKeyRef
API_SECRET_USER=$(kubectl get deployment api -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="DB_USER")].valueFrom.secretKeyRef.name}' 2>/dev/null)
if [ "$API_SECRET_USER" = "postgres-secret" ]; then
    test_passed "API usa secretKeyRef para DB_USER"
else
    test_failed "API deve usar secretKeyRef para credenciais" "Não use 'value:' direto no deployment"
fi

# 3.3 - Verificar se PostgreSQL usa secretKeyRef
if kubectl get statefulset postgres &>/dev/null; then
    PG_RESOURCE_TYPE="statefulset"
elif kubectl get deployment postgres &>/dev/null; then
    PG_RESOURCE_TYPE="deployment"
else
    PG_RESOURCE_TYPE="none"
fi


if [ "$PG_RESOURCE_TYPE" != "none" ]; then
    PG_SECRET_USER=$(kubectl get $PG_RESOURCE_TYPE postgres -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="POSTGRES_USER")].valueFrom.secretKeyRef.name}' 2>/dev/null)
    if [ "$PG_SECRET_USER" = "postgres-secret" ]; then
        test_passed "PostgreSQL usa secretKeyRef para POSTGRES_USER"
    else
        test_failed "PostgreSQL deve usar secretKeyRef para credenciais" "Não use 'value:' direto"
    fi
fi

# 3.4 - Verificar se values.yaml não expõe senhas (warning)
if grep -q "password:" helm/staff-app/values.yaml 2>/dev/null; then
    test_warning "values.yaml ainda contém 'password:' - Em produção, use External Secrets ou Vault"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏥 TESTE 4: Health Checks (Probes)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 4.1 - Verificar Readiness Probe
READINESS_PROBE=$(kubectl get deployment api -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' 2>/dev/null)
if [ "$READINESS_PROBE" = "/health" ]; then
    test_passed "Readiness Probe configurado na API"
else
    test_failed "API deve ter readinessProbe" "Necessário para rolling updates seguros"
fi

# 4.2 - Verificar Liveness Probe
LIVENESS_PROBE=$(kubectl get deployment api -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}' 2>/dev/null)
if [ "$LIVENESS_PROBE" = "/health" ]; then
    test_passed "Liveness Probe configurado na API"
else
    test_failed "API deve ter livenessProbe" "Necessário para detectar falhas"
fi

# 4.3 - Verificar se probes estão funcionando
if [ -n "$API_POD" ]; then
    PROBE_STATUS=$(kubectl get pod $API_POD -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    if [ "$PROBE_STATUS" = "True" ]; then
        test_passed "Health probes estão passando (pod Ready)"
    else
        test_failed "Health probes estão falhando" "Status: $PROBE_STATUS"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💾 TESTE 5: Persistência de Dados (PostgreSQL)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 5.1 - Verificar se PostgreSQL é StatefulSet
if kubectl get statefulset postgres &>/dev/null; then
    test_passed "PostgreSQL configurado como StatefulSet (correto para produção)"
    
    # 5.2 - Verificar PVC
    if kubectl get pvc | grep -q "postgres-storage"; then
        test_passed "PersistentVolumeClaim criado para PostgreSQL"
        
        # Verificar se PVC está Bound
        PVC_STATUS=$(kubectl get pvc -l app=postgres -o jsonpath='{.items[0].status.phase}' 2>/dev/null || kubectl get pvc | grep postgres | awk '{print $2}' | head -n1)
        if [ "$PVC_STATUS" = "Bound" ]; then
            test_passed "PVC está Bound (armazenamento provisionado)"
        else
            test_failed "PVC não está Bound" "Status: $PVC_STATUS"
        fi
    else
        test_failed "PVC não encontrado" "StatefulSet deve ter volumeClaimTemplates"
    fi
else
    test_warning "PostgreSQL está como Deployment (não recomendado para produção)"
    test_info "Em produção, use StatefulSet com PersistentVolumeClaim"
fi

# 5.3 - Verificar se PostgreSQL tem health probes
PG_READINESS=$(kubectl get $PG_RESOURCE_TYPE postgres -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.exec.command}' 2>/dev/null)
if [[ "$PG_READINESS" == *"pg_isready"* ]]; then
    test_passed "PostgreSQL tem readiness probe (pg_isready)"
else
    test_warning "PostgreSQL deveria ter readiness probe com pg_isready"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 TESTE 6: Observabilidade (Prometheus)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 6.1 - Verificar se Prometheus está rodando
if kubectl get deployment prometheus &>/dev/null; then
    PROM_READY=$(kubectl get deployment prometheus -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    if [ "$PROM_READY" -ge 1 ]; then
        test_passed "Prometheus está rodando"
    else
        test_failed "Prometheus não está pronto" "Verifique os logs"
    fi
else
    test_failed "Deployment do Prometheus não encontrado" "Prometheus é necessário para métricas"
fi

# 6.2 - Verificar porta de scrape do Prometheus
SCRAPE_PORT=$(kubectl get configmap prometheus-config -o jsonpath='{.data.prometheus\.yml}' 2>/dev/null | grep -o 'api:[0-9]*' | grep -o '[0-9]*' | head -n1)
if [ "$SCRAPE_PORT" = "9464" ]; then
    test_passed "Prometheus configurado para fazer scrape na porta correta (9464)"
elif [ "$SCRAPE_PORT" = "9999" ]; then
    test_failed "Porta de scrape incorreta" "Deve ser 9464, não 9999"
else
    test_warning "Não foi possível verificar a porta de scrape do Prometheus"
fi

# 6.3 - Verificar se a API expõe métricas
if [ -n "$API_POD" ]; then
    METRICS_RESPONSE=$(kubectl exec -it $API_POD -- wget -qO- http://localhost:9464/metrics 2>/dev/null | head -n 1)
    if [[ "$METRICS_RESPONSE" == *"HELP"* ]] || [[ "$METRICS_RESPONSE" == *"TYPE"* ]]; then
        test_passed "API expõe métricas no formato Prometheus"
    else
        test_warning "Não foi possível verificar métricas da API"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏗️  TESTE 7: Arquitetura e Boas Práticas"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 7.1 - Verificar se containers não rodam como root (bonus)
API_RUN_AS_USER=$(kubectl get deployment api -o jsonpath='{.spec.template.spec.securityContext.runAsNonRoot}' 2>/dev/null)
if [ "$API_RUN_AS_USER" = "true" ]; then
    test_passed "API configurada para não rodar como root (bonus - segurança)"
else
    test_info "Bonus: Configure securityContext.runAsNonRoot: true"
fi

# 7.2 - Verificar resource limits (bonus)
API_MEMORY_LIMIT=$(kubectl get deployment api -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null)
if [ -n "$API_MEMORY_LIMIT" ]; then
    test_passed "Resource limits configurados (bonus - estabilidade)"
else
    test_info "Bonus: Configure resource requests e limits para evitar noisy neighbor"
fi

# 7.3 - Verificar namespace
CURRENT_NS=$(kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}' 2>/dev/null || echo "default")
test_info "Recursos implantados no namespace: $CURRENT_NS"

# 7.4 - Verificar labels consistentes
API_LABELS=$(kubectl get deployment api -o jsonpath='{.spec.template.metadata.labels}' 2>/dev/null)
if [[ "$API_LABELS" == *"app:api"* ]] || [[ "$API_LABELS" == *"app\":\"api"* ]]; then
    test_passed "Labels consistentes nos recursos"
else
    test_warning "Verifique se labels estão consistentes entre resources"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 RESUMO DOS TESTES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total de testes: $TOTAL_TESTS"
echo -e "${GREEN}Passou: $PASSED_TESTS${NC}"
echo -e "${RED}Falhou: $FAILED_TESTS${NC}"
echo ""

# Calcular pontuação
if [ $TOTAL_TESTS -gt 0 ]; then
    SCORE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "📊 PONTUAÇÃO: ${BLUE}$SCORE%${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [ $SCORE -ge 90 ]; then
        echo -e "${GREEN}🎉 EXCELENTE!${NC} Todas as principais correções foram implementadas."
        echo ""
        EXIT_CODE=0
    elif [ $SCORE -ge 70 ]; then
        echo -e "${YELLOW}⚠️  BOM, mas há melhorias necessárias.${NC}"
        echo ""
        EXIT_CODE=1
    else
        echo -e "${RED}❌ INSUFICIENTE.${NC} Várias correções críticas estão faltando."
        echo ""
        EXIT_CODE=2
    fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 CHECKLIST DE REQUISITOS MÍNIMOS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "[ ] Deploy com Helm no Minikube/Kind"
echo "[ ] 2 réplicas da API rodando"
echo "[ ] 1 réplica do PostgreSQL"
echo "[ ] API consegue comunicar com o database"
echo "[ ] Secrets ao invés de texto puro"
echo "[ ] Health checks (readiness/liveness probes)"
echo "[ ] Prometheus coletando métricas"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 PONTOS EXTRAS AVALIADOS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "[ ] StatefulSet para PostgreSQL (ao invés de Deployment)"
echo "[ ] PersistentVolumeClaim para dados do PostgreSQL"
echo "[ ] Health probes no PostgreSQL (pg_isready)"
echo "[ ] Security context (runAsNonRoot)"
echo "[ ] Resource limits configurados"
echo "[ ] Headless service para StatefulSet"
echo ""

exit $EXIT_CODE
