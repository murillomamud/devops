# Script de Validação - Staff DevOps Challenge (Windows PowerShell)
# Este script valida se todas as correções foram implementadas corretamente

$ErrorActionPreference = "Continue"

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🧪 TESTE DE VALIDAÇÃO - STAFF DEVOPS CHALLENGE" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

$TOTAL_TESTS = 0
$PASSED_TESTS = 0
$FAILED_TESTS = 0

# Função para teste
function Test-Passed {
    param([string]$Message)
    Write-Host "✅ PASSOU: $Message" -ForegroundColor Green
    $script:PASSED_TESTS++
    $script:TOTAL_TESTS++
}

function Test-Failed {
    param([string]$Message, [string]$Reason)
    Write-Host "❌ FALHOU: $Message" -ForegroundColor Red
    Write-Host "   Motivo: $Reason" -ForegroundColor Yellow
    $script:FAILED_TESTS++
    $script:TOTAL_TESTS++
}

function Test-Warning {
    param([string]$Message)
    Write-Host "⚠️  AVISO: $Message" -ForegroundColor Yellow
}

function Test-Info {
    param([string]$Message)
    Write-Host "ℹ️  INFO: $Message" -ForegroundColor Cyan
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📦 TESTE 1: Verificando Requisitos Mínimos" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# 1.1 - Verificar se o Helm chart está instalado
$helmList = helm list 2>$null | Select-String "staff"
if ($helmList) {
    Test-Passed "Helm chart 'staff' está instalado"
} else {
    Test-Failed "Helm chart 'staff' não está instalado" "Execute: helm install staff ./helm/staff-app"
}

# 1.2 - Verificar número de réplicas da API
$apiReplicas = kubectl get deployment api -o jsonpath='{.spec.replicas}' 2>$null
if ($apiReplicas -eq 2) {
    Test-Passed "API tem 2 réplicas configuradas"
} else {
    Test-Failed "API deve ter 2 réplicas" "Atual: $apiReplicas réplicas"
}

# 1.3 - Verificar se as réplicas da API estão prontas
$apiReady = kubectl get deployment api -o jsonpath='{.status.readyReplicas}' 2>$null
if ($apiReady -eq 2) {
    Test-Passed "2 réplicas da API estão prontas e rodando"
} else {
    Test-Failed "2 réplicas da API devem estar prontas" "Atual: $apiReady réplicas prontas"
}

# 1.4 - Verificar PostgreSQL
$pgPods = (kubectl get pods -l app=postgres --no-headers 2>$null | Measure-Object).Count
if ($pgPods -eq 1) {
    Test-Passed "1 réplica do PostgreSQL está rodando"
} else {
    Test-Failed "Deve haver exatamente 1 réplica do PostgreSQL" "Encontrado: $pgPods pods"
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🔗 TESTE 2: Conectividade e Funcionalidade" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# 2.1 - Testar endpoint /health da API
$apiPod = kubectl get pod -l app=api -o jsonpath='{.items[0].metadata.name}' 2>$null
if ($apiPod) {
    $healthResponse = kubectl exec -it $apiPod -- wget -qO- http://localhost:3000/health 2>$null
    if ($healthResponse -eq "OK") {
        Test-Passed "Endpoint /health da API responde corretamente"
    } else {
        Test-Failed "Endpoint /health não está funcionando" "Resposta: $healthResponse"
    }
} else {
    Test-Failed "Não foi possível encontrar pod da API" "Verifique se os pods estão rodando"
}

# 2.2 - Testar conexão com banco de dados
if ($apiPod) {
    $dbResponse = kubectl exec -it $apiPod -- wget -qO- http://localhost:3000/db 2>$null
    if ($dbResponse -match "now") {
        Test-Passed "API consegue conectar ao PostgreSQL e retornar dados"
    } else {
        Test-Failed "API não consegue conectar ao PostgreSQL" "Verifique DB_HOST e credenciais"
    }
}

# 2.3 - Verificar se o serviço postgres existe
$pgService = kubectl get service postgres 2>$null
if ($pgService) {
    Test-Passed "Service 'postgres' existe"
    
    # Verificar DB_HOST no deployment
    $dbHost = kubectl get deployment api -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="DB_HOST")].value}' 2>$null
    if ($dbHost -eq "postgres") {
        Test-Passed "DB_HOST configurado corretamente como 'postgres'"
    } else {
        Test-Failed "DB_HOST deve ser 'postgres'" "Atual: $dbHost"
    }
} else {
    Test-Failed "Service 'postgres' não existe" "Crie o service do PostgreSQL"
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🔐 TESTE 3: Segurança (Secrets)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# 3.1 - Verificar se Secret foi criado
$pgSecret = kubectl get secret postgres-secret 2>$null
if ($pgSecret) {
    Test-Passed "Secret 'postgres-secret' foi criado"
} else {
    Test-Failed "Secret 'postgres-secret' não existe" "Credenciais devem estar em Secrets, não em texto puro"
}

# 3.2 - Verificar se API usa secretKeyRef
$apiSecretUser = kubectl get deployment api -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="DB_USER")].valueFrom.secretKeyRef.name}' 2>$null
if ($apiSecretUser -eq "postgres-secret") {
    Test-Passed "API usa secretKeyRef para DB_USER"
} else {
    Test-Failed "API deve usar secretKeyRef para credenciais" "Não use 'value:' direto no deployment"
}

# 3.3 - Verificar se PostgreSQL usa secretKeyRef
$statefulsetExists = kubectl get statefulset postgres 2>$null
$deploymentExists = kubectl get deployment postgres 2>$null

if ($statefulsetExists) {
    $pgResourceType = "statefulset"
} elseif ($deploymentExists) {
    $pgResourceType = "deployment"
} else {
    $pgResourceType = "none"
}

if ($pgResourceType -ne "none") {
    $pgSecretUser = kubectl get $pgResourceType postgres -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="POSTGRES_USER")].valueFrom.secretKeyRef.name}' 2>$null
    if ($pgSecretUser -eq "postgres-secret") {
        Test-Passed "PostgreSQL usa secretKeyRef para POSTGRES_USER"
    } else {
        Test-Failed "PostgreSQL deve usar secretKeyRef para credenciais" "Não use 'value:' direto"
    }
}

# 3.4 - Verificar se values.yaml não expõe senhas (warning)
if (Test-Path "helm/staff-app/values.yaml") {
    $hasPassword = Select-String -Path "helm/staff-app/values.yaml" -Pattern "password:" -Quiet
    if ($hasPassword) {
        Test-Warning "values.yaml ainda contém 'password:' - Em produção, use External Secrets ou Vault"
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🏥 TESTE 4: Health Checks (Probes)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# 4.1 - Verificar Readiness Probe
$readinessProbe = kubectl get deployment api -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' 2>$null
if ($readinessProbe -eq "/health") {
    Test-Passed "Readiness Probe configurado na API"
} else {
    Test-Failed "API deve ter readinessProbe" "Necessário para rolling updates seguros"
}

# 4.2 - Verificar Liveness Probe
$livenessProbe = kubectl get deployment api -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}' 2>$null
if ($livenessProbe -eq "/health") {
    Test-Passed "Liveness Probe configurado na API"
} else {
    Test-Failed "API deve ter livenessProbe" "Necessário para detectar falhas"
}

# 4.3 - Verificar se probes estão funcionando
if ($apiPod) {
    $probeStatus = kubectl get pod $apiPod -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>$null
    if ($probeStatus -eq "True") {
        Test-Passed "Health probes estão passando (pod Ready)"
    } else {
        Test-Failed "Health probes estão falhando" "Status: $probeStatus"
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "💾 TESTE 5: Persistência de Dados (PostgreSQL)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# 5.1 - Verificar se PostgreSQL é StatefulSet
if ($statefulsetExists) {
    Test-Passed "PostgreSQL configurado como StatefulSet (correto para produção)"
    
    # 5.2 - Verificar PVC
    $pvcExists = kubectl get pvc 2>$null | Select-String "postgres-storage"
    if ($pvcExists) {
        Test-Passed "PersistentVolumeClaim criado para PostgreSQL"
        
        # Verificar se PVC está Bound
        $pvcStatus = kubectl get pvc -o jsonpath='{.items[?(@.metadata.name=="postgres-storage-postgres-0")].status.phase}' 2>$null
        if ($pvcStatus -eq "Bound") {
            Test-Passed "PVC está Bound (armazenamento provisionado)"
        } else {
            Test-Failed "PVC não está Bound" "Status: $pvcStatus"
        }
    } else {
        Test-Failed "PVC não encontrado" "StatefulSet deve ter volumeClaimTemplates"
    }
} else {
    Test-Warning "PostgreSQL está como Deployment (não recomendado para produção)"
    Test-Info "Em produção, use StatefulSet com PersistentVolumeClaim"
}

# 5.3 - Verificar se PostgreSQL tem health probes
if ($pgResourceType -ne "none") {
    $pgReadiness = kubectl get $pgResourceType postgres -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.exec.command}' 2>$null
    if ($pgReadiness -match "pg_isready") {
        Test-Passed "PostgreSQL tem readiness probe (pg_isready)"
    } else {
        Test-Warning "PostgreSQL deveria ter readiness probe com pg_isready"
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📊 TESTE 6: Observabilidade (Prometheus)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# 6.1 - Verificar se Prometheus está rodando
$promDeployment = kubectl get deployment prometheus 2>$null
if ($promDeployment) {
    $promReady = kubectl get deployment prometheus -o jsonpath='{.status.readyReplicas}' 2>$null
    if ($promReady -ge 1) {
        Test-Passed "Prometheus está rodando"
    } else {
        Test-Failed "Prometheus não está pronto" "Verifique os logs"
    }
} else {
    Test-Failed "Deployment do Prometheus não encontrado" "Prometheus é necessário para métricas"
}

# 6.2 - Verificar porta de scrape do Prometheus
$prometheusConfig = kubectl get configmap prometheus-config -o jsonpath='{.data.prometheus\.yml}' 2>$null
if ($prometheusConfig -match "api:(\d+)") {
    $scrapePort = $matches[1]
    if ($scrapePort -eq "9464") {
        Test-Passed "Prometheus configurado para fazer scrape na porta correta (9464)"
    } elseif ($scrapePort -eq "9999") {
        Test-Failed "Porta de scrape incorreta" "Deve ser 9464, não 9999"
    }
} else {
    Test-Warning "Não foi possível verificar a porta de scrape do Prometheus"
}

# 6.3 - Verificar se a API expõe métricas
if ($apiPod) {
    $metricsResponse = kubectl exec -it $apiPod -- wget -qO- http://localhost:9464/metrics 2>$null | Select-Object -First 1
    if ($metricsResponse -match "HELP|TYPE") {
        Test-Passed "API expõe métricas no formato Prometheus"
    } else {
        Test-Warning "Não foi possível verificar métricas da API"
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🏗️  TESTE 7: Arquitetura e Boas Práticas" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# 7.1 - Verificar security context
$runAsNonRoot = kubectl get deployment api -o jsonpath='{.spec.template.spec.securityContext.runAsNonRoot}' 2>$null
if ($runAsNonRoot -eq "true") {
    Test-Passed "API configurada para não rodar como root (bonus - segurança)"
} else {
    Test-Info "Bonus: Configure securityContext.runAsNonRoot: true"
}

# 7.2 - Verificar resource limits
$memoryLimit = kubectl get deployment api -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>$null
if ($memoryLimit) {
    Test-Passed "Resource limits configurados (bonus - estabilidade)"
} else {
    Test-Info "Bonus: Configure resource requests e limits para evitar noisy neighbor"
}

# 7.3 - Verificar labels
$apiLabels = kubectl get deployment api -o jsonpath='{.spec.template.metadata.labels}' 2>$null
if ($apiLabels -match "app") {
    Test-Passed "Labels consistentes nos recursos"
} else {
    Test-Warning "Verifique se labels estão consistentes entre resources"
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📝 RESUMO DOS TESTES" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total de testes: $TOTAL_TESTS"
Write-Host "Passou: $PASSED_TESTS" -ForegroundColor Green
Write-Host "Falhou: $FAILED_TESTS" -ForegroundColor Red
Write-Host ""

# Calcular pontuação
if ($TOTAL_TESTS -gt 0) {
    $score = [math]::Round(($PASSED_TESTS * 100 / $TOTAL_TESTS))
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "📊 PONTUAÇÃO: $score%" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    
    if ($score -ge 90) {
        Write-Host "🎉 EXCELENTE! Todas as principais correções foram implementadas." -ForegroundColor Green
        $exitCode = 0
    } elseif ($score -ge 70) {
        Write-Host "⚠️  BOM, mas há melhorias necessárias." -ForegroundColor Yellow
        $exitCode = 1
    } else {
        Write-Host "❌ INSUFICIENTE. Várias correções críticas estão faltando." -ForegroundColor Red
        $exitCode = 2
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🎯 CHECKLIST DE REQUISITOS MÍNIMOS:" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "[ ] Deploy com Helm no Minikube/Kind"
Write-Host "[ ] 2 réplicas da API rodando"
Write-Host "[ ] 1 réplica do PostgreSQL"
Write-Host "[ ] API consegue comunicar com o database"
Write-Host "[ ] Secrets ao invés de texto puro"
Write-Host "[ ] Health checks (readiness/liveness probes)"
Write-Host "[ ] Prometheus coletando métricas"
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "💡 PONTOS EXTRAS AVALIADOS:" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "[ ] StatefulSet para PostgreSQL (ao invés de Deployment)"
Write-Host "[ ] PersistentVolumeClaim para dados do PostgreSQL"
Write-Host "[ ] Health probes no PostgreSQL (pg_isready)"
Write-Host "[ ] Security context (runAsNonRoot)"
Write-Host "[ ] Resource limits configurados"
Write-Host "[ ] Headless service para StatefulSet"
Write-Host ""

exit $exitCode
