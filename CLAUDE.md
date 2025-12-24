# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PentestGPT is an AI-powered autonomous penetration testing agent with a terminal user interface (TUI). It uses an agentic pipeline to solve CTF challenges, Hack The Box machines, and authorized security assessments.

**Published at USENIX Security 2024**: [Paper](https://www.usenix.org/conference/usenixsecurity24/presentation/deng)

**Stack:** Python 3.12+, uv, Docker (Ubuntu 24.04), Textual (TUI), Rich (CLI), Agent SDK

## Common Commands

```bash
# Development
uv sync                           # Install dependencies
uv run pentestgpt --target X      # Run locally

# Testing
make test                         # Run all tests
make test-cov                     # Run tests with coverage
uv run pytest tests/test_controller.py -v  # Run single test file

# Code Quality
make lint                         # Run ruff linter
make format                       # Format code with ruff
make typecheck                    # Run mypy type checking
make check                        # All checks (lint + typecheck)

# Docker Workflow
make install                      # Build Docker image
make connect                      # Connect to container (main usage)
make stop                         # Stop container
make clean-docker                 # Remove everything including config
```

## Architecture

### Entry Point
- `pentestgpt/interface/main.py` - CLI entry, argument parsing, mode selection
- Command: `pentestgpt --target <IP/URL> [--instruction "hint"] [--non-interactive] [--raw] [--debug]`

### Core Layer (`pentestgpt/core/`)
- **agent.py** - `PentestAgent`: Wraps the LLM agent, handles flag detection, logs to `/workspace/pentestgpt-debug.log`
- **backend.py** - `AgentBackend` interface + `ClaudeCodeBackend` implementation (framework-agnostic design)
- **controller.py** - `AgentController`: 5-state lifecycle (IDLE->RUNNING->PAUSED->COMPLETED->ERROR), pause/resume at message boundaries
- **events.py** - `EventBus`: Singleton pub/sub for TUI-agent decoupling (STATE_CHANGED, MESSAGE, TOOL, FLAG_FOUND events)
- **session.py** - `SessionStore`: File-based persistence in `~/.pentestgpt/sessions/`, supports session resumption
- **config.py** - Pydantic settings with `.env` file support

### Interface Layer (`pentestgpt/interface/`)
- **tui.py** - Textual TUI app with real-time activity feed, F1 help, Ctrl+P pause, Ctrl+Q quit
- **components/** - ActivityFeed, SplashScreen, tool-specific Renderers

### System Prompts (`pentestgpt/prompts/`)
- **pentesting.py** - `CTF_SYSTEM_PROMPT`: CTF methodology, flag formats, persistence directives

## Key Patterns

- **Event-Driven**: TUI subscribes to EventBus; agent emits events for state changes, messages, flags
- **Singletons**: `EventBus.get()`, `get_global_tracer()` for global access
- **Abstract Backend**: `AgentBackend` interface allows swapping LLM backends
- **Flag Detection**: Regex patterns in agent.py match `flag{}`, `HTB{}`, `CTF{}`, 32-char hex

## Testing

Tests use pytest with pytest-asyncio. Mock backends for unit tests.

```bash
uv run pytest tests/ -v                           # All tests
uv run pytest tests/test_controller.py -v         # Single file
uv run pytest tests/test_controller.py::test_name # Single test
```

## Docker Notes

- Non-root user: `pentester` with sudo
- Workdir: `/workspace` (mounted from `./workspace`)
- LLM config persisted in `claude-config` volume
- Pre-installed: nmap, netcat, curl, wget, git, ripgrep, tmux

## Legacy Version

The previous multi-LLM version (v0.15) is archived in `legacy/`. It supports:
- OpenAI (GPT-4o, o3, o4-mini)
- Google Gemini
- Deepseek
- Ollama (local LLMs)
- GPT4All

To develop on the legacy version:
```bash
cd legacy
pip install -e .
```

## Benchmark System

The benchmark module (`pentestgpt/benchmark/`) provides both manual orchestration and automated benchmark execution:

```bash
# Manual orchestration (existing)
pentestgpt-benchmark list                              # List all benchmarks
pentestgpt-benchmark list --show-tags                  # Show vulnerability tags
pentestgpt-benchmark list --tags sqli --levels 1      # Filter benchmarks
pentestgpt-benchmark start XBEN-001-24                 # Start a benchmark
pentestgpt-benchmark status                            # Check running benchmarks
pentestgpt-benchmark stop XBEN-001-24                  # Stop a benchmark

# Automated benchmark execution (NEW)
pentestgpt-benchmark run --all --model opus --timeout 1800      # Run all 104 benchmarks
pentestgpt-benchmark run --range 1-10 --pattern-flag           # Run benchmarks 1-10
pentestgpt-benchmark run --ids 1,5,10,25 --timeout 600         # Run specific benchmarks
pentestgpt-benchmark run --retry-failed                         # Retry failed from last run

# Results analysis (NEW)
pentestgpt-benchmark analyze                                    # Analyze latest run
pentestgpt-benchmark analyze logs/benchmark_run_20251219_231946 # Analyze specific run
```

### Benchmark Module Structure
- **config.py** - Configuration (paths, ports, model names, output dir)
- **registry.py** - `BenchmarkRegistry`: Discovers benchmarks from `benchmark.json` files
- **docker.py** - Start/stop containers, load benchmarks, parse flags from .env
- **cli.py** - CLI interface for all commands (list/start/stop/status/run/analyze)
- **models.py** - Data models (BenchmarkConfig, BenchmarkResult, BenchmarkSummary)
- **runner.py** - Main orchestrator for automated execution
- **executor.py** - PentestGPT execution in Docker with timeout handling
- **parser.py** - Output parsing (flags, cost, session info)
- **reporter.py** - Logging and summary generation (JSON/TXT)
- **state.py** - State management for resumption
- **analyzer.py** - Results visualization with Rich tables

### Automated Execution Features
- **Batch execution**: Run multiple benchmarks sequentially with timeout control
- **Early termination**: Monitors for [DONE] marker and stops immediately
- **Flag validation modes**:
  - Standard: Exact match with expected flag
  - `--any-flag`: Accept any flag as success
  - `--pattern-flag`: Only accept FLAG{32+chars} pattern
- **Resume capability**: `--resume` flag skips completed benchmarks from state file
- **Retry failed**: Re-run only failed/timeout/error benchmarks from previous run
- **Model selection**: Choose Claude variant (opus/sonnet/haiku)
- **Comprehensive logging**: Per-benchmark logs, detailed log, JSON/TXT summaries
- **Results analysis**: Rich tables showing success rates by level/tag, cost analysis, failures

### Results Structure
```
logs/
└── benchmark_run_20251219_231946/
    ├── summary.json          # Machine-readable results
    ├── summary.txt           # Human-readable summary
    ├── detailed.log          # Sequential execution log
    └── benchmarks/
        ├── XBEN-001-24.log   # Per-benchmark execution logs
        ├── XBEN-002-24.log
        └── ...
```

## Repository Structure

```
.
├── pentestgpt/           # Main package (agentic version)
│   ├── core/             # Agent, controller, events, session
│   ├── interface/        # TUI and CLI
│   ├── prompts/          # System prompts
│   ├── benchmark/        # Benchmark runner module (manual + automated)
│   └── tools/            # Tool framework
├── benchmark/            # Benchmark suites
│   └── xbow-validation-benchmarks/  # 104 XBOW benchmarks (git submodule)
├── logs/                 # Automated benchmark run results (gitignored)
├── tests/                # Test suite
├── workspace/            # Runtime workspace (Docker mount)
├── legacy/               # Archived v0.15 (multi-LLM)
├── Dockerfile            # Ubuntu 24.04 container
├── docker-compose.yml    # Container orchestration
└── Makefile              # Development commands
```

## Modification Requirements

When modifying code, ensure:
- Adherence to existing architecture and patterns
- Comprehensive tests for new features
- Ensure to run tests after changes, and do further updates to ensure code quality. Always keep the documentation up to date with any architectural changes. Also ensure all tests pass after modifications.