# AssinaZap

Insere automaticamente a **assinatura de quem está atendendo** no topo de cada mensagem
enviada pelo **aplicativo nativo do WhatsApp para Windows** (o da Microsoft Store).

Feito para equipes que atendem clientes em um número compartilhado e precisam identificar
quem respondeu, sem digitar o nome a cada mensagem.

```
Artur | T.I
Boa tarde! Já verifiquei o equipamento e ele está liberado.
```

---

## Por que AutoHotkey e não uma extensão

Extensão de navegador só funciona no **WhatsApp Web**. Quem usa o aplicativo instalado no
computador fica de fora — e é exatamente esse o caso de uso aqui. Por isso o AssinaZap
trabalha no nível do sistema operacional, com AutoHotkey v2.

## Como funciona

O atalho de `Enter` é interceptado **somente quando a janela do WhatsApp está em foco**.
Ao enviar, o script:

1. verifica se existe texto na caixa de mensagem;
2. leva o cursor para o início do texto;
3. digita a assinatura configurada e quebra a linha;
4. volta para o fim e envia.

A área de transferência é sempre restaurada ao valor original.

### Detalhe que custou tempo descobrir

A janela do WhatsApp nativo **não pertence ao processo `WhatsApp.exe`**, como se espera:
ela pertence a `WhatsApp.Root.exe` (pacote MSIX, classe `WinUIDesktopWin32WindowClass`).
O atalho escopa os dois nomes de processo para funcionar nas duas situações.

### Trava de reentrada

A trava que impede o envio duplicado fica em um bloco `try/finally`. Sem isso, qualquer
falha no meio do processo deixava a trava ligada e **a tecla Enter parava de funcionar
para sempre** até reiniciar o script.

## Instalação

1. Instalar o [AutoHotkey v2](https://www.autohotkey.com/) (testado na v2.0.26).
2. Executar `Instalar.bat` — ele cria o atalho e inicia o script.
3. Ícone na bandeja → **Configurar** para definir a assinatura.

Para iniciar junto com o Windows, colocar um atalho do script em `shell:startup`.

## Configuração

| Opção | O que faz |
|---|---|
| **Nome** | Texto da assinatura |
| **Negrito** | Envolve em `*asteriscos*` |
| **Itálico** | Envolve em `_underlines_` |
| **Caixa alta** | Converte para maiúsculas |
| **Quebras** | Uma ou duas linhas entre assinatura e mensagem |
| **Ativo** | Liga e desliga sem fechar o programa |

As preferências ficam em `config.ini`, criado na primeira execução (veja
`config.exemplo.ini`).

## Privacidade

**Sem rede e sem telemetria.** O script não faz nenhuma requisição — tudo acontece na
máquina, e nenhuma mensagem é lida, guardada ou enviada para lugar nenhum.

## Limitação conhecida

Pressionar `Enter` na **caixa de busca** do WhatsApp pode inserir a assinatura no lugar
errado, já que o atalho é escopado pela janela e não pelo campo em foco.

---

Inspirado no [ZapMe](https://zapme.app/pc/), que atende apenas o WhatsApp Web.
