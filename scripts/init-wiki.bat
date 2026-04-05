@echo off
chcp 65001 >nul 2>&1
REM 初始化 Karpathy Wiki 知识库目录结构
REM
REM 用法：init-wiki.bat [目标目录]
REM 默认目标目录：当前目录下的 wiki\
REM
REM 示例：
REM   init-wiki.bat                     在 .\wiki\ 创建
REM   init-wiki.bat C:\Users\me\notes   在指定目录创建

setlocal enabledelayedexpansion

REM 解析参数
if "%~1"=="" (
    set "TARGET_DIR=wiki"
) else (
    set "TARGET_DIR=%~1"
)

REM 获取脚本所在目录
set "SCRIPT_DIR=%~dp0"
set "ASSETS=%SCRIPT_DIR%..\assets"

REM 获取当前日期（格式 YYYY-MM-DD）
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value 2^>nul') do set "DT=%%I"
set "TODAY=%DT:~0,4%-%DT:~4,2%-%DT:~6,2%"

REM 检查目标目录是否已存在
if exist "%TARGET_DIR%" (
    echo ERROR: %TARGET_DIR% 已存在。请选择其他路径或先删除。 1>&2
    exit /b 1
)

REM 检查 assets 目录
set "HAS_ASSETS=1"
if not exist "%ASSETS%" (
    echo WARNING: assets 目录未找到 (%ASSETS%)，将创建空模板文件。 1>&2
    set "HAS_ASSETS=0"
)

echo 正在初始化知识库：%TARGET_DIR%

REM 创建目录结构
mkdir "%TARGET_DIR%\raw" 2>nul
mkdir "%TARGET_DIR%\wiki\index" 2>nul
mkdir "%TARGET_DIR%\outputs\queries" 2>nul
mkdir "%TARGET_DIR%\outputs\reports" 2>nul

REM 从模板创建索引文件
if "%HAS_ASSETS%"=="1" (
    copy /y "%ASSETS%\dashboard-template.md" "%TARGET_DIR%\wiki\index\Dashboard.md" >nul
    copy /y "%ASSETS%\concept-index-template.md" "%TARGET_DIR%\wiki\index\Concept Index.md" >nul
    copy /y "%ASSETS%\source-index-template.md" "%TARGET_DIR%\wiki\index\Source Index.md" >nul
    copy /y "%ASSETS%\log-template.md" "%TARGET_DIR%\log.md" >nul
) else (
    type nul > "%TARGET_DIR%\wiki\index\Dashboard.md"
    type nul > "%TARGET_DIR%\wiki\index\Concept Index.md"
    type nul > "%TARGET_DIR%\wiki\index\Source Index.md"
    type nul > "%TARGET_DIR%\log.md"
)

REM 占位文件，确保空目录可被 git 追踪
type nul > "%TARGET_DIR%\raw\.gitkeep"
type nul > "%TARGET_DIR%\outputs\queries\.gitkeep"
type nul > "%TARGET_DIR%\outputs\reports\.gitkeep"

REM 创建 .gitignore
(
echo # 敏感配置
echo .env
echo.
echo # 系统文件
echo .DS_Store
echo Thumbs.db
echo.
echo # Obsidian 内部缓存（可选排除）
echo # .obsidian/workspace.json
echo # .obsidian/workspace-mobile.json
) > "%TARGET_DIR%\.gitignore"
echo 已创建 .gitignore

REM 创建 .env 模板（API 配置）
if not exist "%TARGET_DIR%\.env" (
    (
    echo # Karpathy Wiki — PDF/图片解析 API 配置
    echo # 请填入你的 API URL 和 Token
    echo LAYOUT_API_URL=https://your-api-url
    echo LAYOUT_API_TOKEN=your-token
    ) > "%TARGET_DIR%\.env"
    echo 已创建 .env 模板，请填写 PDF/图片解析 API 配置
)

REM 替换模板中的日期占位符
if defined TODAY (
    for /r "%TARGET_DIR%" %%F in (*.md) do (
        set "TMPFILE=%%F.tmp"
        powershell -NoProfile -Command "(Get-Content -Path '%%F' -Raw) -replace 'YYYY-MM-DD','%TODAY%' | Set-Content -Path '%%F' -NoNewline" 2>nul
    )
)

echo.
echo 完成！目录结构：
echo   %TARGET_DIR%\
echo   +-- raw\              # 原始资料（不可变）
echo   +-- wiki\
echo   ^|   +-- index\        # Dashboard + Concept Index + Source Index
echo   ^|   +-- ^<领域^>\       # Wiki 文章（按领域子目录）
echo   +-- outputs\
echo   ^|   +-- queries\      # 查询结果
echo   ^|   +-- reports\      # Lint 报告
echo   +-- .gitignore        # Git 排除规则
echo   +-- .env              # API 配置（已被 .gitignore 排除）
echo   +-- log.md            # 操作日志（仅追加）
echo.
echo 下一步：
echo   1. 编辑 %TARGET_DIR%\.env 填写 PDF/图片解析 API 配置（可选）
echo   2. 用 Obsidian 打开 %TARGET_DIR% 作为 vault
echo   3. 运行 /karpathy-wiki ingest ^<文件或URL^> 开始录入资料

endlocal
