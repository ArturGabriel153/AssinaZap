#Requires AutoHotkey v2.0
#SingleInstance Force
;==============================================================
;  AssinaZap — Assinatura automática no WhatsApp (app do PC)
;  Insere seu nome/assinatura em cima da mensagem ao enviar.
;==============================================================

global IniPath  := A_ScriptDir "\config.ini"
global gName    := ""
global gBold    := false
global gItalic  := false
global gUpper   := false
global gBreaks  := 1        ; 1 = quebra simples, 2 = linha em branco
global gEnabled := true
global Sending  := false    ; trava para não disparar em loop

LoadConfig()
BuildTray()

; Mostra a configuração na primeira execução (quando ainda não há nome)
if (Trim(gName) = "")
    ShowSettings()

TrayTip("AssinaZap", "Rodando na bandeja. " (gEnabled ? "Assinatura ATIVA." : "Assinatura desativada."), 1)

;-------------------------------------------------------------
;  HOTKEY: só age dentro da janela do WhatsApp e quando ligado
;-------------------------------------------------------------
; A janela do WhatsApp nativo (Store/site) pertence a WhatsApp.Root.exe.
; Cobrimos também WhatsApp.exe (versões antigas/Electron) por segurança.
#HotIf gEnabled && !Sending && (WinActive("ahk_exe WhatsApp.Root.exe") || WinActive("ahk_exe WhatsApp.exe"))
$Enter::HandleEnter()
$NumpadEnter::HandleEnter()
#HotIf

HandleEnter() {
    global Sending, gBreaks
    Sending := true                 ; trava reentrância; o finally SEMPRE solta
    try {
        sig := BuildSignature()
        ; Sem assinatura, ou caixa vazia -> apenas envia como de costume.
        if (sig = "" || !HasText()) {
            Send "{Enter}"
            return
        }
        SendInput "^{Home}"         ; vai pro início (desfaz a seleção, sem apagar)
        Sleep 10
        SendText(sig)               ; digita o nome formatado (texto literal)
        Loop gBreaks
            SendInput "+{Enter}"    ; Shift+Enter = quebra de linha no WhatsApp
        SendInput "^{End}"          ; volta pro fim da mensagem
        Sleep 40
        SendInput "{Enter}"         ; envia de verdade
    } finally {
        Sleep 50                    ; deixa o Enter sintético assentar
        Sending := false            ; garante que o Enter volte a funcionar mesmo se algo falhar
    }
}

; Há texto digitado na caixa? Usa a área de transferência e a restaura.
HasText() {
    saved := ClipboardAll()
    A_Clipboard := ""
    try {
        SendInput "^a^c"            ; seleciona tudo e copia (Ctrl+Home depois desfaz a seleção)
        if !ClipWait(0.4)           ; nada copiado => caixa vazia
            return false
        return Trim(A_Clipboard) != ""
    } finally {
        A_Clipboard := saved        ; devolve o conteúdo original do usuário
    }
}

BuildSignature() {
    global gName, gBold, gItalic, gUpper
    s := Trim(gName)
    if (s = "")
        return ""
    if gUpper
        s := StrUpper(s)
    if gBold
        s := "*" s "*"              ; *negrito* no WhatsApp
    if gItalic
        s := "_" s "_"              ; _itálico_ no WhatsApp
    return s
}

;-------------------------------------------------------------
;  Configuração (salva/carrega em config.ini)
;-------------------------------------------------------------
LoadConfig() {
    global
    gName    := IniRead(IniPath, "Assinatura", "Nome", "")
    gBold    := IniRead(IniPath, "Assinatura", "Negrito", "0") = "1"
    gItalic  := IniRead(IniPath, "Assinatura", "Italico", "0") = "1"
    gUpper   := IniRead(IniPath, "Assinatura", "CaixaAlta", "0") = "1"
    gBreaks  := (IniRead(IniPath, "Assinatura", "Quebras", "1") = "2") ? 2 : 1
    gEnabled := IniRead(IniPath, "Assinatura", "Ativo", "1") = "1"
}

SaveConfig() {
    global
    IniWrite(gName,                IniPath, "Assinatura", "Nome")
    IniWrite(gBold   ? "1" : "0",  IniPath, "Assinatura", "Negrito")
    IniWrite(gItalic ? "1" : "0",  IniPath, "Assinatura", "Italico")
    IniWrite(gUpper  ? "1" : "0",  IniPath, "Assinatura", "CaixaAlta")
    IniWrite(gBreaks,              IniPath, "Assinatura", "Quebras")
    IniWrite(gEnabled ? "1" : "0", IniPath, "Assinatura", "Ativo")
}

;-------------------------------------------------------------
;  Bandeja (tray)
;-------------------------------------------------------------
BuildTray() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Configurar AssinaZap", (*) => ShowSettings())
    A_TrayMenu.Add("Ativar / Desativar", ToggleEnabled)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Sair", (*) => ExitApp())
    A_TrayMenu.Default := "Configurar AssinaZap"
    UpdateTrayTip()
}

UpdateTrayTip() {
    global gEnabled
    A_IconTip := "AssinaZap — " (gEnabled ? "ATIVO" : "desativado")
}

ToggleEnabled(*) {
    global gEnabled
    gEnabled := !gEnabled
    SaveConfig()
    UpdateTrayTip()
    TrayTip("AssinaZap", gEnabled ? "Assinatura ATIVADA" : "Assinatura desativada", 1)
}

;-------------------------------------------------------------
;  Tela de configuração
;-------------------------------------------------------------
ShowSettings() {
    global gName, gBold, gItalic, gUpper, gBreaks, gEnabled

    g := Gui("+AlwaysOnTop", "AssinaZap — Configuração")
    g.SetFont("s10", "Segoe UI")

    g.Add("Text", "xm", "Seu nome / assinatura:")
    ctlName := g.Add("Edit", "xm w320", gName)

    ctlBold := g.Add("Checkbox", "xm y+12", "Negrito")
    ctlBold.Value := gBold ? 1 : 0
    ctlItal := g.Add("Checkbox", "x+20", "Itálico")
    ctlItal.Value := gItalic ? 1 : 0
    ctlUp := g.Add("Checkbox", "x+20", "Caixa alta")
    ctlUp.Value := gUpper ? 1 : 0

    g.Add("Text", "xm y+14", "Quebra de linha entre o nome e a mensagem:")
    ctlBreak := g.Add("DropDownList", "xm w320 Choose" (gBreaks = 2 ? 2 : 1),
        ["Simples (nome direto em cima)", "Dupla (linha em branco no meio)"])

    ctlEn := g.Add("Checkbox", "xm y+14", "Ativar inserção automática ao enviar")
    ctlEn.Value := gEnabled ? 1 : 0

    g.Add("Text", "xm y+16", "Prévia de como vai aparecer:")
    ctlPrev := g.Add("Edit", "xm w320 r4 ReadOnly -Wrap")

    refresh(*) {
        nm := ctlName.Value
        if (nm = "")
            nm := "Seu nome"
        if ctlUp.Value
            nm := StrUpper(nm)
        if ctlBold.Value
            nm := "*" nm "*"
        if ctlItal.Value
            nm := "_" nm "_"
        sep := (ctlBreak.Value = 2) ? "`r`n`r`n" : "`r`n"
        ctlPrev.Value := nm sep "Sua mensagem aqui..."
    }
    refresh()
    ctlName.OnEvent("Change", refresh)
    ctlBold.OnEvent("Click", refresh)
    ctlItal.OnEvent("Click", refresh)
    ctlUp.OnEvent("Click", refresh)
    ctlBreak.OnEvent("Change", refresh)

    saveAndClose(*) {
        global gName, gBold, gItalic, gUpper, gBreaks, gEnabled
        gName   := ctlName.Value
        gBold   := ctlBold.Value ? true : false
        gItalic := ctlItal.Value ? true : false
        gUpper  := ctlUp.Value ? true : false
        gBreaks := (ctlBreak.Value = 2) ? 2 : 1
        gEnabled := ctlEn.Value ? true : false
        SaveConfig()
        UpdateTrayTip()
        TrayTip("AssinaZap", "Configuração salva!", 1)
        g.Destroy()
    }

    g.Add("Button", "xm y+18 w155 Default", "Salvar").OnEvent("Click", saveAndClose)
    g.Add("Button", "x+10 w155", "Fechar").OnEvent("Click", (*) => g.Destroy())
    g.OnEvent("Close", (*) => g.Destroy())
    g.Show()
}
