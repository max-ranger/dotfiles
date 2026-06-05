param(
    [string]$Title = "Claude Code",
    [string]$Message = "Needs your attention"
)

$ErrorActionPreference = "Stop"

# Read hook JSON from stdin if available and extract a useful message.
if (-not [Console]::IsInputRedirected) {
    $stdin = ""
} else {
    $stdin = [Console]::In.ReadToEnd()
}

if ($stdin) {
    try {
        $payload = $stdin | ConvertFrom-Json
        if ($payload.message) { $Message = [string]$payload.message }
        $cwd = if ($payload.cwd) { Split-Path -Leaf $payload.cwd } else { "" }
        if ($cwd) { $Title = "Claude Code - $cwd" }
    } catch {
        # Ignore parse errors; use defaults.
    }
}

# Trim to safe lengths for the toast template.
if ($Title.Length   -gt 64)  { $Title   = $Title.Substring(0, 64) }
if ($Message.Length -gt 200) { $Message = $Message.Substring(0, 200) }

[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType=WindowsRuntime] | Out-Null

$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(
    [Windows.UI.Notifications.ToastTemplateType]::ToastText02
)

$textNodes = $template.GetElementsByTagName("text")
$textNodes.Item(0).AppendChild($template.CreateTextNode($Title))   | Out-Null
$textNodes.Item(1).AppendChild($template.CreateTextNode($Message)) | Out-Null

$toast = [Windows.UI.Notifications.ToastNotification]::new($template)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Code").Show($toast)
