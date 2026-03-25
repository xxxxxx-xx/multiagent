@echo off
setlocal EnableExtensions

echo ====================================
echo Stopping SuperBizAgent
echo ====================================
echo.

echo [1/4] Stopping FastAPI window...
taskkill /FI "WINDOWTITLE eq SuperBizAgent API*" /F >nul 2>&1
if errorlevel 1 (
    echo [INFO] FastAPI window was not running.
) else (
    echo [INFO] FastAPI window stopped.
)
echo.

echo [2/4] Stopping CLS MCP window...
taskkill /FI "WINDOWTITLE eq CLS MCP Server*" /F >nul 2>&1
if errorlevel 1 (
    echo [INFO] CLS MCP window was not running.
) else (
    echo [INFO] CLS MCP window stopped.
)
echo.

echo [3/4] Stopping Monitor MCP window...
taskkill /FI "WINDOWTITLE eq Monitor MCP Server*" /F >nul 2>&1
if errorlevel 1 (
    echo [INFO] Monitor MCP window was not running.
) else (
    echo [INFO] Monitor MCP window stopped.
)
echo.

echo [4/4] Stopping Docker services...
docker ps --format "{{.Names}}" 2>nul | findstr /I /C:"milvus" >nul
if errorlevel 1 (
    echo [INFO] Milvus containers were not running.
) else (
    docker compose -f vector-database.yml down
    if errorlevel 1 (
        echo [WARN] Docker compose down returned an error.
    ) else (
        echo [INFO] Docker services stopped.
    )
)
echo.

echo ====================================
echo Shutdown finished
echo ====================================
pause
exit /b 0
