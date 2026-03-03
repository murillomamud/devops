#!/bin/bash

# Script para iniciar o projeto Staff DevOps Challenge
# Autor: Setup automation script
# Data: 2026-03-02

set -e  # Sai se houver erro

echo "🚀 Iniciando Staff DevOps Challenge..."
echo ""

# Verificar se kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl não está instalado. Por favor, instale antes de continuar."
    exit 1
fi

# Verificar se Helm está instalado
if ! command -v helm &> /dev/null; then
    echo "❌ Helm não está instalado. Por favor, instale antes de continuar."
    exit 1
fi

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não está instalado. Por favor, instale antes de continuar."
    exit 1
fi

echo "✅ Dependências verificadas"
echo ""

# Detectar ou perguntar qual cluster usar
CLUSTER_TYPE=""

if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    CLUSTER_TYPE="minikube"
    echo "📦 Minikube detectado e rodando"
elif command -v kind &> /dev/null && kind get clusters 2>/dev/null | grep -q "kind"; then
    CLUSTER_TYPE="kind"
    echo "📦 Kind detectado e rodando"
else
    echo "Escolha o cluster Kubernetes local:"
    echo "  1) Minikube"
    echo "  2) Kind"
    read -p "Digite sua escolha (1 ou 2): " choice
    
    case $choice in
        1)
            if ! command -v minikube &> /dev/null; then
                echo "❌ Minikube não está instalado."
                exit 1
            fi
            CLUSTER_TYPE="minikube"
            ;;
        2)
            if ! command -v kind &> /dev/null; then
                echo "❌ Kind não está instalado."
                exit 1
            fi
            CLUSTER_TYPE="kind"
            ;;
        *)
            echo "❌ Escolha inválida"
            exit 1
            ;;
    esac
fi

echo ""

# Iniciar cluster se necessário
if [ "$CLUSTER_TYPE" = "minikube" ]; then
    echo "📦 Usando Minikube..."
    if ! minikube status &> /dev/null; then
        echo "🔄 Iniciando Minikube..."
        minikube start
        echo "✅ Minikube iniciado"
    else
        echo "✅ Minikube já está rodando"
    fi
    echo ""
    
    echo "🔧 Configurando Docker environment do Minikube..."
    eval $(minikube docker-env)
    echo "✅ Docker environment configurado"
    echo ""
    
elif [ "$CLUSTER_TYPE" = "kind" ]; then
    echo "📦 Usando Kind..."
    if ! kind get clusters 2>/dev/null | grep -q "^kind$"; then
        echo "🔄 Criando cluster Kind..."
        kind create cluster --name kind
        echo "✅ Cluster Kind criado"
    else
        echo "✅ Cluster Kind já existe"
    fi
    echo ""
    
    echo "🔧 Configurando contexto do Kind..."
    kubectl config use-context kind-kind
    echo "✅ Contexto configurado"
    echo ""
fi

# Construir a imagem Docker
echo "🏗️  Construindo imagem Docker da aplicação..."
docker build -t staff-app:latest ./app

if [ "$CLUSTER_TYPE" = "kind" ]; then
    echo "📦 Carregando imagem no Kind..."
    kind load docker-image staff-app:latest --name kind
fi

echo "✅ Imagem construída com sucesso"
echo ""

# Instalar/Atualizar Helm chart
echo "📊 Instalando Helm chart..."
if helm list | grep -q "^staff"; then
    echo "🔄 Chart já existe, fazendo upgrade..."
    helm upgrade staff ./helm/staff-app
else
    echo "🆕 Instalando novo chart..."
    helm install staff ./helm/staff-app
fi
echo "✅ Helm chart instalado"
echo ""

# Aguardar pods ficarem prontos
echo "⏳ Aguardando pods ficarem prontos..."
kubectl wait --for=condition=ready pod -l app=api --timeout=120s 2>/dev/null || true
echo ""

# Mostrar status
echo "📋 Status dos recursos:"
echo ""
echo "Pods:"
kubectl get pods
echo ""
echo "Services:"
kubectl get services
echo ""

# Informações úteis
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Projeto iniciado com sucesso usando $CLUSTER_TYPE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 Comandos úteis:"
echo ""
echo "  Ver logs da API:"
echo "    kubectl logs -l app=api -f"
echo ""
echo "  Ver logs do PostgreSQL:"
echo "    kubectl logs -l app=postgres -f"
echo ""
echo "  Ver logs do Prometheus:"
echo "    kubectl logs -l app=prometheus -f"
echo ""

if [ "$CLUSTER_TYPE" = "minikube" ]; then
    echo "  Acessar a API:"
    echo "    minikube service api --url"
    echo ""
    echo "  Acessar o Prometheus:"
    echo "    minikube service prometheus --url"
elif [ "$CLUSTER_TYPE" = "kind" ]; then
    echo "  Acessar a API (port-forward):"
    echo "    kubectl port-forward svc/api 8080:80"
    echo ""
    echo "  Acessar o Prometheus (port-forward):"
    echo "    kubectl port-forward svc/prometheus 9090:9090"
fi

echo ""
echo "  Ver todos os recursos:"
echo "    kubectl get all"
echo ""
echo "  Desinstalar o chart:"
echo "    helm uninstall staff"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
