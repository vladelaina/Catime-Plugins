# Guia de Plugins do Catime

## O que é um Plugin?

Um plugin é um arquivo de script que exibe conteúdo personalizado na janela do Catime. Por exemplo:

- 📺 Estatísticas dos seus vídeos do Bilibili/YouTube
- 📈 Índices NASDAQ e S&P 500 em tempo real
- 🌤️ Previsão do tempo local
- 🌐 Estatísticas de tráfego do seu site
- 💻 Status do servidor
- ……

**Conceito central: Qualquer dado que seu script possa obter pode ser exibido na janela do Catime!**

Além disso, esses dados podem ser colocados em qualquer lugar da tela e redimensionados para qualquer tamanho, assim como a exibição de tempo do Catime — sempre visíveis sem bloquear outras janelas.

**Como funciona:** Seu script escreve em `output.txt` → Catime lê → Exibe na janela. Simples assim!

> **Dica:** Certifique-se de ter o ambiente de execução necessário instalado (por exemplo, Python, Node.js, etc.)

---

## Início Rápido em 30 Segundos

Não quer escrever código? Experimente manualmente primeiro:

### Passo 1: Abrir Pasta de Plugins

Clique com botão direito no ícone do Catime → `Plugins` → `Abrir Pasta de Plugins`

### Passo 2: Editar output.txt

Encontre (ou crie) `output.txt` na pasta e escreva algo:

```
Olá, Catime!
Esta é minha primeira mensagem 🎉
```

### Passo 3: Exibir Conteúdo do Arquivo

Clique com botão direito no ícone do Catime → `Plugins` → `Mostrar Arquivo de Plugin`

**Pronto!** A janela do Catime agora mostra seu conteúdo.

> Esta é a essência dos plugins: **O que você escreve em output.txt aparece na janela**.
> Scripts de plugins apenas automatizam esse processo.

---

## Crie Seu Primeiro Plugin em 3 Passos

### Passo 1: Abrir Pasta de Plugins

Clique com botão direito no ícone do Catime → `Plugins` → `Abrir Pasta de Plugins`

### Passo 2: Criar Arquivo de Script

Crie um novo arquivo nesta pasta, por exemplo, `hello.py`:

```python
with open('output.txt', 'w', encoding='utf-8') as f:
    f.write('Olá, Catime!')
```

**Apenas algumas linhas!**

### Passo 3: Executar Plugin

1. Clique com botão direito no ícone do Catime
2. `Plugins` → Clique em `hello.py`
3. Na primeira vez perguntará se você confia, clique em "Confiar e Executar"

**Pronto!** A janela agora mostra "Olá, Catime!"

---

## Ponto Chave

O que seu script escrever em `output.txt`, o Catime exibe. A exibição atualiza automaticamente quando o arquivo é atualizado.

---

## Tags Especiais (Opcional)

Use estas tags se necessário:

| Tag | Função | Exemplo |
|-----|--------|---------|
| `<md></md>` | Habilitar formatação Markdown | `<md>**negrito** *itálico*</md>` |
| `<catime></catime>` | Mostrar tempo do temporizador | `Executando <catime></catime>` → `Executando 00:05:30` |
| `<exit>N</exit>` | Fechar plugin automaticamente após N segundos | `<exit>5</exit>` → fecha após 5 segundos |
| `<fps:N>` | Atualizar N vezes por segundo (padrão 2, intervalo 1-100) | `<fps:10>` → 10 atualizações por segundo |
| `<color:valor></color>` | Definir cor do texto (suporta gradientes) | `<color:#FF0000>vermelho</color>` |
| `<font:caminho></font>` | Definir fonte (caminho do arquivo de fonte) | `<font:C:\Windows\Fonts\comic.ttf>divertido</font>` |
| `![](caminho)` | Exibir imagem (caminho local ou URL) | `![](clima.png)` ou `![](https://example.com/img.png)` |
| `![LxA](caminho)` | Exibir imagem com tamanho específico | `![100x50](logo.png)` ou `![200](logo.png)` (apenas largura) |

> **Sobre `<fps:N>`:** A atualização padrão é a cada 500ms (2 vezes por segundo). Para dados que atualizam rapidamente, aumente a taxa até `<fps:100>` (100 vezes por segundo).

> **Sobre cor e fonte:** Estas tags funcionam independentemente (não precisam de `<md>`) e podem ser aninhadas. Caminhos de fonte suportam caminhos absolutos, variáveis de ambiente ou caminhos relativos ao diretório do plugin.

---

## Linguagens Suportadas

Python, PowerShell, Batch, JavaScript... até Shell, Ruby, PHP, Lua e **mais de 90 linguagens** são suportadas! Desde que você tenha o interpretador instalado, qualquer linguagem funciona.

> **Recomendado:** Use **PowerShell (.ps1)** ou **Batch (.bat)** — integrados ao Windows, sem instalação necessária, menor uso de recursos.

---

## É Seguro?

Ao executar um plugin pela primeira vez, o Catime perguntará:

- **Cancelar** = Não executar
- **Executar Uma Vez** = Executar apenas desta vez, perguntará novamente na próxima
- **Confiar e Executar** = Sempre executar automaticamente

Se você modificar um arquivo de plugin, o Catime perguntará novamente para prevenir adulteração.

---

## Perguntas Frequentes

### Plugin não mostra conteúdo?

Verifique:
- O caminho do arquivo está correto (script deve escrever em `output.txt` no mesmo diretório)
- O interpretador está instalado (por exemplo, scripts Python precisam de Python instalado)

### Como parar um plugin?

Clique com botão direito no ícone → Plugins → Clique novamente no plugin em execução (marcado com ✓)

### Precisa reiniciar após editar?

Não! O Catime detecta mudanças automaticamente e reexecuta o plugin (hot reload).

### Posso executar múltiplos plugins?

Não, apenas um por vez. Clique em outro plugin para trocar; o atual para automaticamente.

### Plugins continuam executando após fechar o Catime?

Não. O Catime para todos os processos de plugins ao fechar.

---

## Notas

⚠️ **Evite subprocessos aninhados**

Use um único processo para completar tarefas. Se seu script gera subprocessos (por exemplo, usando `start` em `.bat`), eles podem não ser limpos corretamente.

---

**É isso! Agora vá criar seu primeiro plugin!** 🚀
