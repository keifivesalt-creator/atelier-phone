@echo off
rem スマホのページを GitHub Pages に公開する / 更新する（中身は publish.ps1）
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish.ps1"
pause
