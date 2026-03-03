# 🖥️ Compatibilidade Multi-Plataforma - Scripts de Teste

## ✅ Scripts Disponíveis

Este repositório contém **dois scripts de validação** com funcionalidades idênticas:

| Script | Plataforma | Comando |
|--------|-----------|---------|
| `test.sh` | Linux / macOS / WSL | `./test.sh` |
| `test.ps1` | Windows (PowerShell) | `.\test.ps1` |

---

## 🚀 Como Executar

### No Linux / macOS / WSL

```bash
# Tornar executável (primeira vez)
chmod +x test.sh

# Executar
./test.sh
```

### No Windows (PowerShell)

```powershell
# Executar diretamente
.\test.ps1

# Ou com execução de scripts habilitada
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\test.ps1
```

### No Windows (Git Bash / WSL)

```bash
# Usar o script bash
./test.sh
```

---

## ⚠️ Problemas Conhecidos por Plataforma

### Windows CMD/PowerShell Nativo

❌ **NÃO use `test.sh` no CMD ou PowerShell nativo**
- O script bash não funciona fora de ambientes Unix-like
- Use `test.ps1` ao invés

✅ **Use `test.ps1`**
- Script nativo do PowerShell
- Cores e formatação funcionam corretamente

### Git Bash no Windows

✅ **Use `test.sh`**
- O Git Bash emula ambiente Unix
- Suporta scripts bash nativamente

### WSL (Windows Subsystem for Linux)

✅ **Use `test.sh`**
- WSL é Linux completo
- Funciona como em ambiente Linux nativo

---

## 🔍 Diferenças Técnicas

| Aspecto | test.sh | test.ps1 |
|---------|---------|----------|
| Linguagem | Bash | PowerShell |
| Variáveis | `$VAR` | `$VAR` |
| Condicionais | `if [ "$X" = "Y" ]` | `if ($X -eq "Y")` |
| Redirecionamento | `2>/dev/null` | `2>$null` |
| Pipes | `\|` | `\|` |
| Regex | `grep -E` | `Select-String` |
| Cores | ANSI codes | `-ForegroundColor` |

---

## 📊 Validações Realizadas

Ambos os scripts validam:

1. ✅ Requisitos Mínimos (Helm, réplicas, pods)
2. ✅ Conectividade (health, database)  
3. ✅ Segurança (Secrets, secretKeyRef)
4. ✅ Health Checks (probes)
5. ✅ Persistência (StatefulSet, PVC)
6. ✅ Observabilidade (Prometheus)
7. ✅ Boas Práticas (security context, limits)

---

## 🎨 Output Colorido

### Linux/macOS
```
✅ PASSOU: API tem 2 réplicas configuradas
❌ FALHOU: PostgreSQL deve usar secretKeyRef
⚠️  AVISO: Configure securityContext
```

### Windows PowerShell
```
✅ PASSOU: API tem 2 réplicas configuradas  (verde)
❌ FALHOU: PostgreSQL deve usar secretKeyRef  (vermelho)
⚠️  AVISO: Configure securityContext  (amarelo)
```

---

## 🐛 Troubleshooting

### "permission denied" no Linux/macOS
```bash
chmod +x test.sh
```

### "execution policy" no Windows
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### "command not found: kubectl"
```bash
# Instale kubectl
# Linux: apt/yum install kubectl
# macOS: brew install kubectl
# Windows: choco install kubernetes-cli
```

### Script não encontra recursos
```bash
# Verifique o contexto do kubectl
kubectl config current-context

# Liste todos os recursos
kubectl get all
```

---

## 📝 Saída de Exemplo

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧪 TESTE DE VALIDAÇÃO - STAFF DEVOPS CHALLENGE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 TESTE 1: Verificando Requisitos Mínimos
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ PASSOU: Helm chart 'staff' está instalado
✅ PASSOU: API tem 2 réplicas configuradas
...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 RESUMO DOS TESTES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total de testes: 22
Passou: 22
Falhou: 0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 PONTUAÇÃO: 100%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎉 EXCELENTE! Todas as principais correções foram implementadas.
```

---

## 🎯 Exit Codes

Ambos os scripts retornam:
- `0`: 90-100% (Excelente)
- `1`: 70-89% (Bom, mas precisa melhorias)
- `2`: 0-69% (Insuficiente)

Útil para integração CI/CD:
```bash
./test.sh && echo "Passou!" || echo "Falhou!"
```

---

## 📚 Mais Informações

- Ver detalhes dos testes: Veja `ANSWER_KEY.md`
- Entender requisitos: Veja `README.md`
- Guia de correções: Veja `ANSWER_KEY.md`
