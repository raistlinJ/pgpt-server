<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>

<!-- PROJECT SHIELDS -->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![Discord][discord-shield]][discord-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">

<h3 align="center">PentestGPT</h3>

  <p align="center">
    AI-Powered Autonomous Penetration Testing Agent
    <br />
    <strong>Published at USENIX Security 2024</strong>
    <br />
    <br />
    <a href="https://www.usenix.org/conference/usenixsecurity24/presentation/deng">Research Paper</a>
    ·
    <a href="https://github.com/GreyDGL/PentestGPT/issues">Report Bug</a>
    ·
    <a href="https://github.com/GreyDGL/PentestGPT/issues">Request Feature</a>
  </p>
</div>

<!-- ABOUT THE PROJECT -->
<a href="https://trendshift.io/repositories/3770" target="_blank"><img src="https://trendshift.io/api/badge/repositories/3770" alt="GreyDGL%2FPentestGPT | Trendshift" style="width: 250px; height: 55px;" width="250" height="55"/></a>

> [!WARNING]
> **PentestGPT is a research prototype only**
>
> PentestGPT is a research prototype that pioneered the use of GenAI in cybersecurity. Please be aware of third-party services claiming to offer paid PentestGPT products - the original project is free and open-source.

---

## Demo

### Installation
[![Installation Demo](https://asciinema.org/a/761661.svg)](https://asciinema.org/a/761661)

[Watch on YouTube](https://www.youtube.com/watch?v=RUNmoXqBwVg)

### PentestGPT in Action
[![PentestGPT Demo](https://asciinema.org/a/761663.svg)](https://asciinema.org/a/761663)

[Watch on YouTube](https://www.youtube.com/watch?v=cWi3Yb7RmZA)

---

## What's New in v1.0 (Agentic Upgrade)

- **Autonomous Agent** - Agentic pipeline for intelligent, autonomous penetration testing
- **Session Persistence** - Save and resume penetration testing sessions
- **Docker-First** - Isolated, reproducible environment with security tools pre-installed
- **SSH + Local Web Config** - Start the container, configure local LLM routing in a browser, and run PentestGPT over SSH
- **YAML Runtime Launcher** - Persist LLM, PentestGPT, and MCP settings in `/workspace/pentestgpt.yml`
- **MCP Server Management** - Add, list, and remove Claude Code MCP servers from the local web UI
- **Benchmark Automation** - Run, resume, retry, and analyze XBEN benchmark batches

> **In Progress**: Multi-model support for OpenAI, Gemini, and other LLM providers

---

## Features

- **AI-Powered Challenge Solver** - Leverages LLM advanced reasoning to perform penetration testing and CTFs
- **Live Walkthrough** - Tracks steps in real-time as the agent works through challenges
- **Multi-Category Support** - Web, Crypto, Reversing, Forensics, PWN, Privilege Escalation
- **Real-Time Feedback** - Watch the AI work with live activity updates
- **Configurable Local Routing** - Route Claude Code traffic through Claude Code Router to OpenAI-compatible servers, Ollama, or OpenRouter
- **MCP-Aware Workflow** - Attach project, local, or user scoped MCP servers from the browser UI or YAML
- **Extensible Architecture** - Clean, modular design ready for future enhancements

---

## Quick Start

### Prerequisites

- **Docker** (required) - [Install Docker](https://docs.docker.com/get-docker/)
- **Linux helper**: On a fresh Linux host, run `./install_prereq.sh` after cloning to install Docker, Docker Compose, `git`, `make`, and `curl`, then add your user to the `docker` group.
- **LLM Provider** (choose one):
  - Anthropic API Key from [console.anthropic.com](https://console.anthropic.com/)
  - Claude OAuth Login (requires Claude subscription)
  - OpenRouter for alternative models at [openrouter.ai](https://openrouter.ai/keys)
  - [Tutorial: Using Local Models with Claude Code](https://docs.google.com/document/d/1ixK7x-wlr5t5TYZJdfm75UME5KnPCpS46boLkUXKg1w/edit?usp=sharing)


### Installation

```bash
# Clone
git clone --recurse-submodules <your-repo-url> pgpt-server
cd pgpt-server

# Fresh Linux host only: install Docker/Compose and host prerequisites
chmod +x install_prereq.sh
./install_prereq.sh

# If the script added you to the docker group, refresh group membership
newgrp docker

# Build
make install

# Configure authentication (optional; Local LLM is the default in this image)
make config

# Start the container
make start

# Configure local LLM endpoint and model routing in your browser
open http://127.0.0.1:8080

# Connect to container over SSH
make connect
```

> **Note**: The `--recurse-submodules` flag downloads the benchmark suite. If you already cloned without it, run: `git submodule update --init --recursive`

### Fresh Linux Host Prerequisites

`install_prereq.sh` performs the host setup needed before `make install`:

- installs `git`, `make`, `curl`, CA certificates, and GPG tooling where needed
- installs Docker Engine and the Docker Compose plugin when missing
- asks whether to create the `docker` group if needed
- asks whether to add the current user to the `docker` group
- enables and starts the Docker service
- verifies Docker and Compose are reachable

Run it with:

```bash
./install_prereq.sh
```

If Docker only works with `sudo` immediately after the script finishes, refresh your shell:

```bash
newgrp docker
```

For unattended installs, pre-answer the Docker group prompts:

```bash
PGPT_DOCKER_GROUP=yes PGPT_DOCKER_GROUP_USER=yes ./install_prereq.sh
```

On remote Linux hosts, forward the web UI to your laptop:

```bash
ssh -L 8080:127.0.0.1:8080 youruser@linux-host
```

### Try a Benchmark

```bash
uv run pentestgpt-benchmark start XBEN-037-24
```

Then connect into the container and run:

```bash
pentestgpt --target http://host.docker.internal:8000
```

### Commands Reference

| Command | Description |
|---------|-------------|
| `make install` | Install local dependencies and build the Docker image |
| `make config` | Configure authentication mode and API keys |
| `make start` | Start container in the background |
| `make connect` | Start container and connect over SSH |
| `make ssh` | SSH to a running container |
| `make web` | Print the local web config UI URL |
| `make attach` | Attach to the container TTY |
| `make shell` | Open a new bash shell in the running container |
| `make logs` | Follow Docker Compose logs |
| `make stop` | Stop container (config persists) |
| `make clean-docker` | Remove everything including config |

Default local endpoints:

- Web config UI: `http://127.0.0.1:8080`
- SSH: `ssh -p 2222 pentester@127.0.0.1`
- Default SSH password: `pentestgpt`

Common Docker Compose overrides:

| Variable | Purpose |
|----------|---------|
| `PENTESTGPT_AUTH_MODE` | Authentication mode: `local`, `openrouter`, `anthropic`, or `manual` |
| `PENTESTGPT_WEB_PORT` | Host port for the web config UI, default `8080` |
| `PENTESTGPT_SSH_PORT` | Host port for SSH, default `2222` |
| `PENTESTGPT_SSH_PASSWORD` | Password for the `pentester` account |
| `ANTHROPIC_API_KEY` | Anthropic API key for `anthropic` mode |
| `OPENROUTER_API_KEY` | OpenRouter API key for `openrouter` mode |

The container entrypoint also honors `PENTESTGPT_SSH_AUTHORIZED_KEYS`, `PENTESTGPT_WEB_ENABLED`, `PENTESTGPT_RUNTIME_CONFIG`, and `PENTESTGPT_CCR_LOG` if you inject those variables directly into the container.

---

## Usage

```bash
# Interactive TUI mode (default)
pentestgpt --target 10.10.11.234

# Non-interactive mode
pentestgpt --target 10.10.11.100 --non-interactive

# With challenge context
pentestgpt --target 10.10.11.50 --instruction "WordPress site, focus on plugin vulnerabilities"

# Custom Claude model
pentestgpt --target 10.10.11.50 --model claude-sonnet-4-5-20250929

# Resume or inspect sessions
pentestgpt --target 10.10.11.234 --resume
pentestgpt --target 10.10.11.234 --session-id SESSION_ID
pentestgpt --target 10.10.11.234 --list-sessions

# Debugging output modes
pentestgpt --target 10.10.11.234 --raw --debug
```

**Keyboard Shortcuts:** `F1` Help | `Ctrl+P` Pause/Resume | `Ctrl+Q` Quit

---

## Using Local LLMs

PentestGPT supports routing requests to local LLM servers (LM Studio, Ollama, text-generation-webui, etc.) running on your host machine.

### Prerequisites

- Local LLM server with an OpenAI-compatible API endpoint
  - **LM Studio**: Enable server mode (default port 1234)
  - **Ollama**: Run `ollama serve` (default port 11434)

### Setup

```bash
# Start your local LLM server on the host machine
# Then start PentestGPT and open the web config UI
make start
open http://127.0.0.1:8080

# Save your provider, model, and context settings, then SSH in
make connect
```

### Customizing Models

Use the web config UI to customize:

- **Provider**: OpenAI-compatible or Ollama
- **API base URL**: Your host LLM server URL
  - OpenAI-compatible default: `http://host.docker.internal:1234/v1/chat/completions`
  - Ollama default: `http://host.docker.internal:11434`
- **Enforce SSL**: Requires `https://` for OpenAI-compatible endpoints when enabled
- **Fetch models**: Pulls model names from `/v1/models` or Ollama `/api/tags`
- **Model**: The selected model used by all hidden CCR routes
- **Context window length**: Saved as CCR's long-context threshold

The model dropdown starts empty. Use **Fetch models** to load the list from your configured provider, then save.

The UI writes the persisted YAML config at `/workspace/pentestgpt.yml`, generates the CCR config at `/home/pentester/.claude-code-router/config.json`, and restarts Claude Code Router after each save.

The main page also shows a live activity feed under the model routing form that combines PentestGPT events with Claude Code Router output.

You can run the whole configured flow in one shot:

```bash
pentestgpt-run --target TARGET
```

`pentestgpt-run` reads `/workspace/pentestgpt.yml`, starts Claude Code Router, applies any MCP servers declared in the optional `mcp.servers` YAML section, and launches `pentestgpt`. You can also put the target and run flags in YAML under `pentestgpt`.

Useful launcher commands:

```bash
pentestgpt-run --target http://host.docker.internal:8000 --non-interactive
pentestgpt-run --configure-only          # write CCR/MCP config without launching PentestGPT
pentestgpt-run --dry-run --target TARGET # print the pentestgpt command that would run
pentestgpt-run --skip-mcp --target TARGET
```

The launcher accepts the same run controls as `pentestgpt`, including `--instruction`, `--model`, `--verbose`, `--debug`, `--raw`, `--resume`, `--session-id`, `--list-sessions`, `--no-telemetry`, and repeated `--extra-arg` values.

Example YAML:

```yaml
llm:
  provider: openai-compatible
  # Use "ollama" with api_base_url: http://host.docker.internal:11434 for Ollama.
  api_base_url: http://host.docker.internal:1234/v1
  api_key: ""
  enforce_ssl: false
  models:
    - local-model-name
  selected_model: local-model-name
  context_window: 60000
pentestgpt:
  target: ""
  instruction: ""
  model: ""
  non_interactive: false
  verbose: false
  debug: false
  raw: false
  resume: false
  session_id: ""
  list_sessions: false
  no_telemetry: false
  extra_args: []
mcp:
  servers:
    - name: my-mcp
      transport: http
      scope: project
      command_or_url: http://host.docker.internal:3000/mcp
      args: []
      env: []
      headers: []
```

### MCP Servers

The web UI MCP tab is disabled for now. Use the Claude Code CLI over SSH to list, add, and remove MCP servers. It supports `stdio`, `http`, and `sse` transports; `project`, `local`, and `user` scopes; plus optional arguments, environment variables, and HTTP headers. Project-scoped servers are configured from `/workspace`, which is mounted from `./workspace`.

You can also manage MCP servers over SSH:

```bash
claude mcp list
claude mcp add --scope project --transport stdio filesystem -- npx -y @modelcontextprotocol/server-filesystem /workspace
claude mcp add --scope project --transport http my-mcp http://host.docker.internal:3000/mcp
claude mcp remove --scope project my-mcp
```

### Troubleshooting

- **Connection refused**: Ensure your LLM server is running and listening on the configured port
- **Docker networking**: Use `host.docker.internal` (not `localhost`) to access host services from Docker
- **Port conflict**: Override local ports with `PENTESTGPT_WEB_PORT` or `PENTESTGPT_SSH_PORT`
- **Check CCR logs**: Inside the container, run `cat /tmp/ccr.log`

---

## Telemetry

PentestGPT collects anonymous usage data to help improve the tool. This data is sent to our [Langfuse](https://langfuse.com) project and includes:
- Session metadata (target type, duration, completion status)
- Tool execution patterns (which tools are used, not the actual commands)
- Flag detection events (that a flag was found, not the flag content)

**No sensitive data is collected** - command outputs, credentials, or actual flag values are never transmitted.

### Opting Out

```bash
# Via command line flag
pentestgpt --target 10.10.11.234 --no-telemetry

# Via environment variable
export LANGFUSE_ENABLED=false
```

---

## Benchmarks

PentestGPT includes 100+ vulnerability challenges for testing and development.

```bash
pentestgpt-benchmark list                    # List all benchmarks
pentestgpt-benchmark list --levels 1         # Filter by difficulty
pentestgpt-benchmark list --tags sqli        # Filter by vulnerability type
pentestgpt-benchmark start XBEN-037-24       # Start a benchmark
pentestgpt-benchmark status                  # Check running benchmarks
pentestgpt-benchmark stop XBEN-037-24        # Stop a benchmark
pentestgpt-benchmark list --show-tags        # Show all available tags
```

**Available Tags:** `sqli`, `xss`, `idor`, `ssti`, `ssrf`, `lfi`, `rce`

Automated benchmark runs write logs and summaries to `logs/benchmark_run_*`:

```bash
pentestgpt-benchmark run --range 1-10 --timeout 900 --model sonnet
pentestgpt-benchmark run --ids 1,5,10 --resume
pentestgpt-benchmark run --all --any-flag
pentestgpt-benchmark run --retry-failed
pentestgpt-benchmark run --retry-failed logs/benchmark_run_YYYYMMDD_HHMMSS
pentestgpt-benchmark analyze
pentestgpt-benchmark analyze logs/benchmark_run_YYYYMMDD_HHMMSS
```

Model aliases for benchmark runs are `opus`, `sonnet`, and `haiku`. Use `--pattern-flag` when you only want strict `FLAG{...}` matches to count as a successful flag capture.

---

## Development

### Prerequisites

- **uv** (required) - Python package manager: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- **Claude Code CLI** - Configure with `claude login` or `export ANTHROPIC_API_KEY='your-key'`
  - [Tutorial: Using Local Models with Claude Code](https://docs.google.com/document/d/1ixK7x-wlr5t5TYZJdfm75UME5KnPCpS46boLkUXKg1w/edit?usp=sharing)

### Local Development

```bash
uv sync                                      # Install dependencies
uv run pentestgpt --target 10.10.11.234      # Run locally
```

### Project Commands

```bash
make dev-install      # Install local dev dependencies
make test             # Run pytest except Docker tests
make test-unit        # Run unit tests
make test-integration # Run integration tests
make test-docker      # Run Docker tests
make test-fast        # Run non-slow, non-Docker tests
make lint             # Run ruff linter
make lint-fix         # Apply safe ruff fixes
make format           # Format with ruff
make format-check     # Check formatting
make typecheck        # Run mypy
make ci               # Run full CI simulation (lint, format, typecheck, test, build)
make ci-quick         # Quick CI without build step
make ci-full          # CI plus Docker compose validation/build/tests
```

---

## Legacy Version

The previous multi-LLM version (v0.15) supporting OpenAI, Gemini, Deepseek, and Ollama is archived in [`legacy/`](legacy/):

```bash
cd legacy && pip install -e . && pentestgpt --reasoning gpt-4o
```

---

## Citation

If you use PentestGPT in your research, please cite our paper:

```bibtex
@inproceedings{299699,
  author = {Gelei Deng and Yi Liu and Víctor Mayoral-Vilches and Peng Liu and Yuekang Li and Yuan Xu and Tianwei Zhang and Yang Liu and Martin Pinzger and Stefan Rass},
  title = {{PentestGPT}: Evaluating and Harnessing Large Language Models for Automated Penetration Testing},
  booktitle = {33rd USENIX Security Symposium (USENIX Security 24)},
  year = {2024},
  isbn = {978-1-939133-44-1},
  address = {Philadelphia, PA},
  pages = {847--864},
  url = {https://www.usenix.org/conference/usenixsecurity24/presentation/deng},
  publisher = {USENIX Association},
  month = aug
}
```

---

## License

Distributed under the MIT License. See `LICENSE.md` for more information.

**Disclaimer**: This tool is for educational purposes and authorized security testing only. The authors do not condone any illegal use. Use at your own risk.

---

## Contact

- **Gelei Deng** - [![LinkedIn][linkedin-shield]][linkedin-url] - gelei.deng@ntu.edu.sg
- **Yi Liu** - yi009@e.ntu.edu.sg
- **Yuekang Li** - yuekang.li@unsw.edu.au
- **Víctor Mayoral Vilches** - [![LinkedIn][linkedin-shield]][linkedin-url2] - v.mayoralv@gmail.com
- **Peng Liu** - liu_peng@i2r.a-star.edu.sg

---

## Acknowledgments

- Research supported by [Quantstamp](https://www.quantstamp.com/) and [NTU Singapore](https://www.ntu.edu.sg/)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/GreyDGL/PentestGPT.svg?style=for-the-badge
[contributors-url]: https://github.com/GreyDGL/PentestGPT/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/GreyDGL/PentestGPT.svg?style=for-the-badge
[forks-url]: https://github.com/GreyDGL/PentestGPT/network/members
[stars-shield]: https://img.shields.io/github/stars/GreyDGL/PentestGPT.svg?style=for-the-badge
[stars-url]: https://github.com/GreyDGL/PentestGPT/stargazers
[issues-shield]: https://img.shields.io/github/issues/GreyDGL/PentestGPT.svg?style=for-the-badge
[issues-url]: https://github.com/GreyDGL/PentestGPT/issues
[license-shield]: https://img.shields.io/github/license/GreyDGL/PentestGPT.svg?style=for-the-badge
[license-url]: https://github.com/GreyDGL/PentestGPT/blob/master/LICENSE.md
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/gelei-deng-225a10112/
[linkedin-url2]: https://www.linkedin.com/in/vmayoral/
[discord-shield]: https://dcbadge.vercel.app/api/server/eC34CEfEkK
[discord-url]: https://discord.gg/eC34CEfEkK
