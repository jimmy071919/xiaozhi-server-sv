import importlib
import json
from pathlib import Path
import sys
import types

import pytest


fake_logger_module = types.ModuleType("config.logger")
setattr(fake_logger_module, "setup_logging", lambda: None)
sys.modules["config.logger"] = fake_logger_module
fake_base_module = types.ModuleType("core.providers.llm.base")
setattr(fake_base_module, "LLMProviderBase", object)
sys.modules["core.providers.llm.base"] = fake_base_module
mod = importlib.import_module("core.providers.llm.codex_oauth.codex_oauth")
LLMProvider = mod.LLMProvider


class FakeResponse:
    def __init__(self, payload=None, lines=None):
        self.payload = payload
        self.lines = lines or []
        self.status_code = 200

    def raise_for_status(self):
        return None

    def json(self):
        return self.payload

    def iter_lines(self):
        return iter(self.lines)

    def __enter__(self):
        return self

    def __exit__(self, *_):
        return False


def config():
    return {
        "model_name": "gpt-test",
        "service_tier": "priority",
        "_model_id": "model-1",
        "_broker_url": "http://manager/xiaozhi",
        "_server_secret": "server-secret",
    }


def test_broker_credentials_are_not_part_of_model_config_or_response_body(monkeypatch):
    seen = {}

    def fake_post(url, **kwargs):
        seen["broker_url"] = url
        seen["broker_headers"] = kwargs["headers"]
        return FakeResponse({
            "code": 0,
            "data": {
                "accessToken": "oauth-access-token",
                "accountId": "acct-1",
                "expiresAt": "2999-01-01T00:00:00",
            },
        })

    def fake_stream(method, url, **kwargs):
        seen["request_url"] = url
        seen["request_headers"] = kwargs["headers"]
        seen["request_json"] = kwargs["json"]
        return FakeResponse(lines=[
            "data: " + json.dumps({"type": "response.output_text.delta", "delta": "hello"}),
            "data: [DONE]",
        ])

    monkeypatch.setattr(mod.httpx, "post", fake_post)
    monkeypatch.setattr(mod.httpx, "stream", fake_stream)
    provider = LLMProvider(config())
    assert list(provider.response("session", [
        {"role": "system", "content": "be concise"},
        {"role": "user", "content": "hi"},
    ])) == ["hello"]
    assert seen["broker_headers"]["Authorization"] == "Bearer server-secret"
    assert seen["request_headers"]["Authorization"] == "Bearer oauth-access-token"
    assert seen["request_headers"]["ChatGPT-Account-ID"] == "acct-1"
    assert "oauth-access-token" not in json.dumps(seen["request_json"])
    assert seen["request_json"]["input"][0]["role"] == "developer"
    assert seen["request_json"]["store"] is False
    assert seen["request_json"]["service_tier"] == "priority"


def test_response_with_functions_sends_native_tool_schema_and_yields_completed_call(monkeypatch):
    seen = {}

    def fake_post(url, **kwargs):
        return FakeResponse({
            "code": 0,
            "data": {
                "accessToken": "oauth-access-token",
                "accountId": "acct-1",
                "expiresAt": "2999-01-01T00:00:00",
            },
        })

    def fake_stream(method, url, **kwargs):
        seen["request_json"] = kwargs["json"]
        return FakeResponse(lines=[
            "data: " + json.dumps({"type": "response.output_text.delta", "delta": "Checking"}),
            "data: " + json.dumps({
                "type": "response.output_item.done",
                "item": {
                    "type": "function_call",
                    "id": "fc_1",
                    "call_id": "call_1",
                    "name": "set_volume",
                    "arguments": '{"volume": 30}',
                },
            }),
            "data: [DONE]",
        ])

    monkeypatch.setattr(mod.httpx, "post", fake_post)
    monkeypatch.setattr(mod.httpx, "stream", fake_stream)
    provider = LLMProvider(config())
    calls = list(provider.response_with_functions("session", [
        {"role": "user", "content": "Set volume to 30"},
    ], functions=[{
        "type": "function",
        "function": {
            "name": "set_volume",
            "description": "Set the output volume",
            "parameters": {"type": "object", "properties": {"volume": {"type": "integer"}}},
        },
    }]))

    assert seen["request_json"]["tools"] == [{
        "type": "function",
        "name": "set_volume",
        "description": "Set the output volume",
        "parameters": {"type": "object", "properties": {"volume": {"type": "integer"}}},
    }]
    assert calls[0] == ("Checking", None)
    assert calls[1][0] is None
    assert calls[1][1][0].id == "call_1"
    assert calls[1][1][0].type == "function"
    assert calls[1][1][0].function.name == "set_volume"
    assert calls[1][1][0].function.arguments == '{"volume": 30}'


def test_tool_call_history_uses_responses_function_items():
    body = LLMProvider._request_body([
        {"role": "assistant", "content": None, "tool_calls": [{
            "id": "call_1",
            "type": "function",
            "function": {"name": "set_volume", "arguments": '{"volume": 30}'},
        }]},
        {"role": "tool", "tool_call_id": "call_1", "content": "Volume set"},
    ], "gpt-test")
    assert body["input"] == [
        {
            "type": "function_call",
            "call_id": "call_1",
            "name": "set_volume",
            "arguments": '{"volume": 30}',
        },
        {
            "type": "function_call_output",
            "call_id": "call_1",
            "output": "Volume set",
        },
    ]


def test_migration_preserves_existing_models_and_adds_separate_provider():
    repo_root = next(parent for parent in Path(__file__).resolve().parents if (parent / "main/manager-api").is_dir())
    sql = (repo_root / "main/manager-api/src/main/resources/db/changelog/202610191130.sql").read_text()
    assert "DELETE FROM `ai_model_provider`" in sql
    assert "SYSTEM_LLM_codex_subscription" in sql
    assert "SYSTEM_LLM_codex_oauth" in sql
    assert "UPDATE `ai_model_provider`" not in sql
    assert "UPDATE `ai_model_config`" not in sql


def test_incomplete_broker_response_fails_closed(monkeypatch):
    monkeypatch.setattr(mod.httpx, "post", lambda *a, **k: FakeResponse({"code": 0, "data": {}}))
    provider = LLMProvider(config())
    with pytest.raises(RuntimeError, match="failed|incomplete"):
        list(provider.response("session", [{"role": "user", "content": "hi"}]))
