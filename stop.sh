#!/bin/bash

# Script para parar e limpar o projeto Staff DevOps Challenge
# Autor: Setup automation script
# Data: 2026-03-02

set -e  # Sai se houver erro

echo "🛑 Parando Staff DevOps Challenge..."
echo ""

# Verificar se Helm está instalado
if ! command -v helm &> /dev/null; then
    echo "❌ Helm não está instalado."
    exit 1
fi

# Verificar se kubectl está disponível
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl não está instalado."
    exit 1
fi

# Detectar cluster type
CLUSTER_TYPE=""
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    CLUSTER_TYPE="minikube"
elif command -v kind &> /dev/null && kind get clusters 2>/dev/null | grep -q "kind"; then
    CLUSTER_TYPE="kind"
else
    echo "ℹ️  Nenhum cluster ativo detectado"
fi

# 1. Desinstalar Helm chart
echo "📦 Desinstalando Helm chart..."
if helm list | grep -q "^staff"; then
    helm uninstall staff
    echo "✅ Chart desinstalado"
else
    echo "ℹ️  Chart 'staff' não encontrado (já foi removido)"
fi
echo ""

# 2. Verificar recursos restantes
echo "🔍 Verificando recursos restantes..."
REMAINING_PODS=$(kubectl get pods 2>/dev/null | grep -E "api|postgres|prometheus" || true)
if [ -n "$REMAINING_PODS" ]; then
    echo "⚠️  Alguns pods ainda estão presentes:"
    echo "$REMAINING_PODS"
    echo ""
    echo "Aguardando remoção completa..."
    sleep 5
fi

REMAINING_SERVICES=$(kubectl get services 2>/dev/null | grep -E "api|postgres|prometheus" || true)
if [ -n "$REMAINING_SERVICES" ]; then
    echo "⚠️  Alguns services ainda estão presentes:"
    echo "$REMAINING_SERVICES"
fi
echo ""

if [ -z "$CLUSTER_TYPE" ]; then
    echo "✅ Limpeza concluída!"
    exit 0
fi

# 3. Limpar imagens Docker (opcional)
echo "🗑️  Deseja remover a imagem Docker? (y/N)"
read -t 10 -r REMOVE_IMAGE || REMOVE_IMAGE="n"
if [[ $REMOVE_IMAGE =~ ^[Yy]$ ]]; then
    if [ "$CLUSTER_TYPE" = "minikube" ]; then
        echo "🔄 Configurando Docker environment do Minikube..."
        eval $(minikube docker-env)
    fi
    echo "🗑️  Removendo imagem staff-app:latest..."
    docker rmi staff-app:latest 2>/dev/null || echo "ℹ️  Imagem já foi removida"
    echo "✅ Imagem removida"
else
    echo "ℹ️  Mantendo imagem Docker"
fi
echo ""

# 4. Parar/Deletar cluster (opcional)
if [ "$CLUSTER_TYPE" = "minikube" ]; then
    echo "🛑 Deseja parar o Minikube? (y/N)"
    read -t 10 -r STOP_CLUSTER || STOP_CLUSTER="n"
    if [[ $STOP_CLUSTER =~ ^[Yy]$ ]]; then
        echo "🔄 Parando Minikube..."
        minikube stop
        echo "✅ Minikube parado"
    else
        echo "ℹ️  Minikube continua rodando"
    fi
    echo ""
    
    echo "💀 Deseja DELETAR o cluster Minikube completamente? (y/N)"
    read -t 10 -r DELETE_CLUSTER || DELETE_CLUSTER="n"
    if [[ $DELETE_CLUSTER =~ ^[Yy]$ ]]; then
        echo "⚠️  ATENÇÃO: Isso vai remover TUDO do Minikube!"
        echo "Tem certeza? Digite 'DELETE' para confirmar:"
        read -t 10 -r CONFIRM || CONFIRM="no"
        if [[ $CONFIRM == "DELETE" ]]; then
            echo "🗑️  Deletando cluster Minikube..."
            minikube delete
            echo "✅ Cluster deletado"
        else
            echo "ℹ️  Operação cancelada"
        fi
    else
        echo "ℹ️  Cluster Minikube preservado"
    fi
    
elif [ "$CLUSTER_TYPE" = "kind" ]; then
    echo "💀 Deseja DELETAR o cluster Kind? (y/N)"
    read -t 10 -r DELETE_CLUSTER || DELETE_CLUSTER="n"
    if [[ $DELETE_CLUSTER =~ ^[Yy]$ ]]; then
        echo "🗑️  Deletando cluster Kind..."
        kind delete cluster --name kind
        echo "✅ Cluster Kind deletado"
    else
        echo "ℹ️  Cluster Kind preservado"
    fi
fi

echo ""

# 5. Status final
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Limpeza concluída!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -n "$CLUSTER_TYPE" ]; then
    echo "📋 Status do $CLUSTER_TYPE:"
    echo ""
    
    if [ "$CLUSTER_TYPE" = "minikube" ]; then
        if minikube status &> /dev/null; then
            echo "Minikube: ✅ Rodando"
            echo ""
            echo "Recursos no cluster:"
            kubectl get all 2>/dev/null || echo "  Nenhum recurso encontrado"
        else
            echo "Minikube: ⏹️  Parado/Removido"
        fi
    elif [ "$CLUSTER_TYPE" = "kind" ]; then
        if kind get clusters 2>/dev/null | grep -q "kind"; then
            echo "Kind: ✅ Rodando"
            echo ""
            echo "Recursos no cluster:"
            kubectl get all 2>/dev/null || echo "  Nenhum recurso encontrado"
        else
            echo "Kind: ⏹️  Removido"
        fi
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Para reiniciar o projeto, execute:"
echo "   ./start.sh"
echo ""
