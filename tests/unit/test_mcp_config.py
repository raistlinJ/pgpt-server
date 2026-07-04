"""Tests for Claude Code MCP config helpers."""

import pytest

from pentestgpt.server.mcp_config import (
    MCPAddRequest,
    MCPRemoveRequest,
    build_mcp_add_command,
    build_mcp_remove_command,
    parse_mcp_add_payload,
    parse_mcp_remove_payload,
)


def test_build_http_mcp_add_command() -> None:
    """HTTP MCP servers are added with URL, headers, and scope."""
    request = MCPAddRequest(
        name="sentry",
        transport="http",
        scope="project",
        command_or_url="https://mcp.sentry.dev/mcp",
        headers=["Authorization: Bearer token"],
    )

    assert build_mcp_add_command(request) == [
        "claude",
        "mcp",
        "add",
        "--scope",
        "project",
        "--transport",
        "http",
        "-H",
        "Authorization: Bearer token",
        "sentry",
        "https://mcp.sentry.dev/mcp",
    ]


def test_build_stdio_mcp_add_command() -> None:
    """Stdio MCP servers are added after the command separator."""
    request = MCPAddRequest(
        name="filesystem",
        transport="stdio",
        scope="project",
        command_or_url="npx",
        args=["-y", "@modelcontextprotocol/server-filesystem", "/workspace"],
        env=["DEBUG=1"],
    )

    assert build_mcp_add_command(request) == [
        "claude",
        "mcp",
        "add",
        "--scope",
        "project",
        "--transport",
        "stdio",
        "-e",
        "DEBUG=1",
        "filesystem",
        "--",
        "npx",
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/workspace",
    ]


def test_parse_mcp_add_payload_splits_args() -> None:
    """String args are shell-split for stdio servers."""
    request = parse_mcp_add_payload(
        {
            "name": "tools",
            "transport": "stdio",
            "scope": "project",
            "command_or_url": "npx",
            "args": '-y "some server"',
            "env": "API_KEY=value",
        }
    )

    assert request.args == ["-y", "some server"]
    assert request.env == ["API_KEY=value"]


def test_parse_mcp_add_payload_rejects_invalid_http_url() -> None:
    """HTTP transports require an HTTP URL."""
    with pytest.raises(ValueError, match="http:// or https://"):
        parse_mcp_add_payload(
            {
                "name": "bad",
                "transport": "http",
                "scope": "project",
                "command_or_url": "localhost:3000/mcp",
            }
        )


def test_parse_mcp_add_payload_rejects_bad_name() -> None:
    """Names are restricted to safe Claude MCP identifiers."""
    with pytest.raises(ValueError, match="letters"):
        parse_mcp_add_payload(
            {
                "name": "bad name",
                "transport": "stdio",
                "scope": "project",
                "command_or_url": "npx",
            }
        )


def test_build_remove_command_with_scope() -> None:
    """Remove can target a specific scope."""
    request = MCPRemoveRequest(name="tools", scope="project")

    assert build_mcp_remove_command(request) == [
        "claude",
        "mcp",
        "remove",
        "--scope",
        "project",
        "tools",
    ]


def test_parse_remove_payload_allows_any_scope() -> None:
    """An empty remove scope lets Claude choose whichever scope contains the server."""
    request = parse_mcp_remove_payload({"name": "tools", "scope": ""})

    assert request.name == "tools"
    assert request.scope is None
