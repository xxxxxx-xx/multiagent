@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo ====================================
echo Starting SuperBizAgent
echo ====================================
echo.

where python >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python was not found in PATH.
    echo [HINT] Install Python 3.11+ and try again.
    pause
    exit /b 1
)

where uv >nul 2>&1
if errorlevel 1 (
    set "USE_UV=0"
    echo [INFO] uv not found. Falling back to pip.
) else (
    set "USE_UV=1"
    echo [INFO] uv detected.
)
echo.

echo [1/7] Preparing virtual environment...
if exist ".venv\Scripts\python.exe" (
    echo [INFO] Existing virtual environment found.
    if "%USE_UV%"=="1" (
        call uv sync
        if errorlevel 1 (
            echo [WARN] uv sync failed. Falling back to pip install -e .
            call ".venv\Scripts\python.exe" -m pip install -e .
            if errorlevel 1 goto :install_failed
        )
    ) else (
        call ".venv\Scripts\python.exe" -m pip install -e .
        if errorlevel 1 goto :install_failed
    )
) else (
    echo [INFO] Creating .venv with python -m venv...
    python -m venv .venv
    if errorlevel 1 (
        echo [ERROR] Failed to create the virtual environment.
        pause
        exit /b 1
    )

    call ".venv\Scripts\python.exe" -m pip install --upgrade pip
    if errorlevel 1 (
        echo [ERROR] Failed to upgrade pip.
        pause
        exit /b 1
    )

    if "%USE_UV%"=="1" (
        call uv sync
        if errorlevel 1 (
            echo [WARN] uv sync failed. Falling back to pip install -e .
            call ".venv\Scripts\python.exe" -m pip install -e .
            if errorlevel 1 goto :install_failed
        )
    ) else (
        call ".venv\Scripts\python.exe" -m pip install -e .
        if errorlevel 1 goto :install_failed
    )
)

set "PYTHON_CMD=%CD%\.venv\Scripts\python.exe"
echo [INFO] Python executable: %PYTHON_CMD%
echo.

echo [2/7] Starting Milvus...
docker ps --format "{{.Names}}" 2>nul | findstr /I /C:"milvus-standalone" >nul
if errorlevel 1 (
    docker compose -f vector-database.yml up -d --pull never etcd minio standalone
    if errorlevel 1 (
        echo [ERROR] Failed to start Docker services.
        echo [HINT] Make sure Docker Desktop is running and the required images already exist locally.
        pause
        exit /b 1
    )
    echo [INFO] Waiting 10 seconds for Milvus to warm up...
    timeout /t 10 /nobreak >nul
) else (
    echo [INFO] Milvus is already running.
)
echo.

echo [3/7] Starting CLS MCP server...
start "CLS MCP Server" /min "%PYTHON_CMD%" mcp_servers\cls_server.py
timeout /t 2 /nobreak >nul
echo.

echo [4/7] Starting Monitor MCP server...
start "Monitor MCP Server" /min "%PYTHON_CMD%" mcp_servers\monitor_server.py
timeout /t 2 /nobreak >nul
echo.

echo [5/7] Starting FastAPI...
start "SuperBizAgent API" "%PYTHON_CMD%" -m uvicorn app.main:app --host 0.0.0.0 --port 9900
echo [INFO] Waiting for API to start...
timeout /t 5 /nobreak >nul
echo.

echo [6/7] Checking API health...
set "HEALTH_OK=0"
for /L %%I in (1,1,15) do (
    curl -s http://localhost:9900/health >nul 2>&1
    if not errorlevel 1 (
        set "HEALTH_OK=1"
        goto :health_ready
    )
    timeout /t 2 /nobreak >nul
)

:health_ready
if "%HEALTH_OK%"=="1" (
    echo [INFO] API is responding.
) else (
    echo [WARN] API did not respond to /health yet.
)
echo.

echo [7/7] Uploading seed documents...
if exist "aiops-docs\*.md" (
    for %%F in (aiops-docs\*.md) do (
        echo     Uploading %%~nxF
        curl -s -X POST http://localhost:9900/api/upload -F "file=@%%F" >nul 2>&1
    )
    echo [INFO] Seed document upload finished.
) else (
    echo [INFO] No markdown files found in aiops-docs.
)
echo.

echo ====================================
echo Startup finished
echo ====================================
echo Web UI:       http://localhost:9900
echo API docs:     http://localhost:9900/docs
echo Health check: http://localhost:9900/health
echo Stop script:  stop-windows.bat
echo ====================================
pause
exit /b 0

:install_failed
echo [ERROR] Dependency installation failed.
echo [HINT] Check your network connection and Python package index access.
pause
exit /b 1
