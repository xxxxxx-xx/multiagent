# SuperBizAgent

> An enterprise-oriented conversational assistant and AIOps helper that supports RAG-based knowledge Q&A and automated diagnostic workflows.

[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109+-green.svg)](https://fastapi.tiangolo.com/)
[![LangChain](https://img.shields.io/badge/LangChain-latest-orange.svg)](https://www.langchain.com/)

## Overview

SuperBizAgent combines:

- conversational Q&A powered by Qwen-compatible models,
- RAG-based document retrieval backed by Milvus,
- AIOps diagnosis built with a Plan-Execute-Replan workflow,
- MCP-based access to log and monitoring tools,
- a lightweight web UI for chat, streaming output, file upload, and diagnostics.

## Key Features

- Intelligent chat
  LangChain-based multi-turn conversations with both standard and streaming responses.
- RAG knowledge base
  Supports document upload, automatic chunking, embedding, vector indexing, and retrieval.
- AIOps diagnosis
  Uses a Plan-Execute-Replan workflow to generate step-by-step diagnostic reports.
- Web interface
  Includes quick chat, streaming chat, file upload, AI Ops entry points, and session history.
- MCP integration
  Connects the agent to log-query and monitoring-query tools.

## Tech Stack

- Backend: FastAPI, Python
- Agent framework: LangChain, LangGraph
- LLM provider: DashScope / Qwen
- Vector database: Milvus
- Tool protocol: MCP (Model Context Protocol)
- Frontend: static HTML, CSS, and JavaScript

## Prerequisites

- Python 3.11 to 3.13
- Docker Desktop or a working Docker Engine
- A valid DashScope API key

## Quick Start

### Linux/macOS

```bash
# 1. Clone the repository
git clone <repository_url>
cd super_biz_agent_py

# 2. Create a virtual environment and install dependencies
# Option A: uv (recommended)
pip install uv
uv venv
source .venv/bin/activate
uv pip install -e .

# Option B: pip
python -m venv .venv
source .venv/bin/activate
pip install -e .

# 3. Edit the environment file
vim .env

# 4. One-command initialization
make init

# 5. Start all services
make start
```

### Windows

#### Recommended: use the startup script

```powershell
.\start-windows.bat
.\stop-windows.bat
```

Notes:

- The startup script prepares `.venv`, starts the Milvus stack, launches both MCP servers, starts FastAPI, and uploads seed documents from `aiops-docs/`.
- The current script starts `etcd`, `minio`, and `standalone` only, and assumes the required Docker images already exist locally.

#### Manual startup

```powershell
# 1. Clone the repository
git clone <repository_url>
cd super_biz_agent_py

# 2. Create a virtual environment and install dependencies
# Option A: uv
pip install uv
uv venv
.venv\Scripts\activate
uv pip install -e .

# Option B: pip
python -m venv .venv
.venv\Scripts\activate
pip install -e .

# 3. Edit the environment file
notepad .env

# 4. Start Docker Desktop and launch Milvus core services
docker compose -f vector-database.yml up -d etcd minio standalone

# 5. Start the MCP servers in separate terminals
python mcp_servers/cls_server.py
python mcp_servers/monitor_server.py

# 6. Start the FastAPI application
python -m uvicorn app.main:app --host 0.0.0.0 --port 9900

# 7. Upload seed documents after the API is ready
for %f in (aiops-docs\*.md) do curl -X POST http://localhost:9900/api/upload -F "file=@%f"
```

## Service URLs

- Web UI: `http://localhost:9900`
- API docs: `http://localhost:9900/docs`
- Health check: `http://localhost:9900/health`

## API Endpoints

| Feature | Method | Path | Description |
|---|---|---|---|
| Chat | `POST` | `/api/chat` | Standard non-streaming chat response |
| Streaming chat | `POST` | `/api/chat_stream` | SSE streaming chat response |
| AIOps diagnosis | `POST` | `/api/aiops` | Streaming diagnostic workflow |
| File upload | `POST` | `/api/upload` | Upload and index a document |
| Health check | `GET` | `/health` | Service and Milvus status check |

### Example Requests

```bash
# Standard chat
curl -X POST "http://localhost:9900/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"Id":"session-123","Question":"Hello"}'

# Streaming chat
curl -X POST "http://localhost:9900/api/chat_stream" \
  -H "Content-Type: application/json" \
  -d '{"Id":"session-123","Question":"Hello"}' \
  --no-buffer

# AIOps diagnosis
curl -X POST "http://localhost:9900/api/aiops" \
  -H "Content-Type: application/json" \
  -d '{"session_id":"session-123"}' \
  --no-buffer
```

## Project Structure

```text
super_biz_agent_py/
|-- app/
|   |-- main.py
|   |-- config.py
|   |-- api/
|   |   |-- chat.py
|   |   |-- aiops.py
|   |   |-- file.py
|   |   `-- health.py
|   |-- services/
|   |   |-- rag_agent_service.py
|   |   |-- aiops_service.py
|   |   |-- vector_store_manager.py
|   |   |-- vector_embedding_service.py
|   |   |-- vector_index_service.py
|   |   |-- vector_search_service.py
|   |   `-- document_splitter_service.py
|   |-- agent/
|   |   |-- mcp_client.py
|   |   `-- aiops/
|   |-- tools/
|   |   |-- knowledge_tool.py
|   |   `-- time_tool.py
|   |-- core/
|   |   |-- llm_factory.py
|   |   `-- milvus_client.py
|   `-- utils/
|-- static/
|   |-- index.html
|   |-- app.js
|   `-- styles.css
|-- mcp_servers/
|   |-- cls_server.py
|   |-- monitor_server.py
|   `-- README.md
|-- aiops-docs/
|-- uploads/
|-- volumes/
|-- .env
|-- Makefile
|-- start-windows.bat
|-- stop-windows.bat
|-- vector-database.yml
|-- pyproject.toml
|-- uv.lock
`-- README.md
```

## Configuration

Configure the application through `.env`:

```bash
# App settings
APP_NAME=SuperBizAgent
DEBUG=false
HOST=0.0.0.0
PORT=9900

# DashScope / Qwen settings
DASHSCOPE_API_KEY=your-api-key
DASHSCOPE_API_BASE=https://dashscope.aliyuncs.com/compatible-mode/v1
DASHSCOPE_MODEL=qwen-max
DASHSCOPE_EMBEDDING_MODEL=text-embedding-v4

# Milvus settings
MILVUS_HOST=localhost
MILVUS_PORT=19530
MILVUS_TIMEOUT=10000

# RAG settings
RAG_TOP_K=3
RAG_MODEL=qwen-max
CHUNK_MAX_SIZE=800
CHUNK_OVERLAP=100

# MCP settings
MCP_CLS_TRANSPORT=streamable-http
MCP_CLS_URL=http://localhost:8003/mcp
MCP_MONITOR_TRANSPORT=streamable-http
MCP_MONITOR_URL=http://localhost:8004/mcp
```

## AIOps Workflow

The AIOps module is built around a Plan-Execute-Replan loop:

1. Planner creates a diagnostic plan.
2. Executor runs the current step and calls tools.
3. Replanner evaluates results and either continues or finalizes the report.
4. The system streams intermediate progress and returns a final Markdown report.

Current MCP servers use mock or locally generated data by default. They are suitable for demos and development, and can be extended to connect to real log and monitoring systems.

## Development Commands

```bash
# Project lifecycle
make init
make start
make stop
make restart

# Dependency management
make install-dev
make sync

# Docker
make up
make down

# Code quality
make format
make lint
```

## Troubleshooting

### Windows: `make` is not available

Use the provided batch scripts instead:

```powershell
.\start-windows.bat
.\stop-windows.bat
```

### Windows: PowerShell execution policy blocks scripts

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
```

Or run the scripts from `cmd.exe`.

### Port conflict

```powershell
netstat -ano | findstr :9900
taskkill /F /PID <PID>
```

### DashScope API key issues

```bash
# Linux/macOS
grep DASHSCOPE_API_KEY .env

# Windows
type .env | findstr DASHSCOPE_API_KEY
```

### Milvus connection issues

```bash
# Check container status
docker compose -f vector-database.yml ps

# Restart Milvus core services
docker compose -f vector-database.yml restart etcd minio standalone
```

### Service startup failures

Linux/macOS:

```bash
tail -f logs/app_$(date +%Y-%m-%d).log
lsof -i :9900
lsof -i :8003
lsof -i :8004
```

Windows:

```powershell
$today = Get-Date -Format "yyyy-MM-dd"
type logs\app_$today.log
netstat -ano | findstr :9900
netstat -ano | findstr :8003
netstat -ano | findstr :8004
```

## References

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [LangChain Documentation](https://python.langchain.com/)
- [LangGraph Documentation](https://langchain-ai.github.io/langgraph/)
- [DashScope](https://dashscope.aliyun.com/)
- [Model Context Protocol](https://modelcontextprotocol.io/)

## License

Author: `xxxxx-xx`

MIT License
