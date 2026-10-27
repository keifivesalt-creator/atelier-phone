# スマホのページ（このフォルダ）を GitHub Pages に公開する / 更新する（2026-10-27）
# 1回目: GitHub にログイン（ブラウザが開く）→ リポジトリ atelier-phone を作る → Pages をオン → リンクを Google ドライブに書く
# 2回目から: 変わったファイルを push するだけ（ログインはもう聞かれない）
# ページにはプログラムだけ。記録は Supabase にあって、合言葉（%LOCALAPPDATA%\atelier_agent\phone_token.txt）がないと読めない

# "Stop" にすると、gh や git がエラー出力に書いただけ（「まだリポジトリがない」・push の進み具合など）で止まってしまう
# （Windows PowerShell 5.1）。なので止めずに、大事なところは $LASTEXITCODE で確かめる
$ErrorActionPreference = "Continue"
$gh = "C:\Program Files\GitHub CLI\gh.exe"
$repo = "atelier-phone"
Set-Location -LiteralPath $PSScriptRoot

& $gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "GitHub にログインします。ブラウザが開いたら、画面に出た8けたのコードを入れて「Authorize」を押してください。"
    & $gh auth login --hostname github.com --git-protocol https --web --scopes "repo"
    if ($LASTEXITCODE -ne 0) { throw "ログインできませんでした" }
}
& $gh auth setup-git
$login = (& $gh api user --jq .login).Trim()
$id = (& $gh api user --jq .id).Trim()
Write-Host "GitHub: $login"

if (-not (Test-Path .git)) { git init -b main | Out-Null }
# 公開リポジトリにメールアドレスが載らないように、GitHub の noreply アドレスでコミットする
git config user.name $login
git config user.email "$id+$login@users.noreply.github.com"
git add -A
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    git commit -q -m "スマホのページを更新" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
}

& $gh repo view "$login/$repo" *> $null
if ($LASTEXITCODE -ne 0) {
    & $gh repo create $repo --public --source . --remote origin --push --description "アトリエ・エージェントをスマホで見るページ（記録は入っていません）"
    if ($LASTEXITCODE -ne 0) { throw "リポジトリを作れませんでした" }
} else {
    if (-not (git remote)) { git remote add origin "https://github.com/$login/$repo.git" }
    git push -u origin main
    if ($LASTEXITCODE -ne 0) { throw "push できませんでした" }
}

# GitHub Pages（main ブランチのいちばん上）をオン。もうオンならそのまま
& $gh api "repos/$login/$repo/pages" *> $null
if ($LASTEXITCODE -ne 0) {
    & $gh api -X POST "repos/$login/$repo/pages" -f "source[branch]=main" -f "source[path]=/" | Out-Null
}
$url = "https://$login.github.io/$repo/"

# iPhone で開くリンク（合言葉つき）を、本人の Google ドライブにだけ書く
$token = (Get-Content -LiteralPath "$env:LOCALAPPDATA\atelier_agent\phone_token.txt" -Raw).Trim()
$folder = "G:\マイドライブ\atelier_agent_iphone"
if (Test-Path $folder) {
    $text = "アトリエ・エージェント（スマホのページ）`r`n`r`n" +
            "iPhone の Safari でこのリンクを開いて、共有ボタン →「ホーム画面に追加」するとアプリのように使えます。`r`n" +
            "リンクの # のあとが合言葉です。ほかの人に教えないでください（知っている人は記録を見られます）。`r`n`r`n" +
            "$url#t=$token`r`n"
    [IO.File]::WriteAllText("$folder\スマホのページ.txt", $text, [Text.UTF8Encoding]::new($true))
    Write-Host "リンクを $folder\スマホのページ.txt に書きました。"
}
Write-Host "公開しました: $url （はじめは表示されるまで1〜2分かかります）"
