import json
import time
from datetime import datetime, timezone
from types import SimpleNamespace

import httpx

from config.logger import setup_logging
from core.providers.llm.base import LLMProviderBase

TAG = __name__
logger = setup_logging()


class LLMProvider(LLMProviderBase):
    """Native ChatGPT Codex Responses provider.

    OAuth credentials never enter this provider's configuration. A server-secret protected
    manager-api broker returns a current access token and account id immediately before use.
    """

    RESPONSES_URL = "https://chatgpt.com/backend-api/codex/responses"

    def __init__(self, config):
        self.model_name = config.get("model_name", "gpt-6-sol")
        self.service_tier = config.get("service_tier", "priority")
        self.model_id = config.get("_model_id")
        self.broker_url = config.get("_broker_url", "").rstrip("/")
        self.server_secret = config.get("_server_secret")
        self.timeout = float(config.get("timeout", 300))
        if not self.model_id or not self.broker_url or not self.server_secret:
            raise ValueError("codex_oauth requires manager-api URL, server secret, and model id")
        self._broker_token = None
        self._broker_account_id = None
        self._broker_expires_at = 0

    def _get_credentials(self):
        if self._broker_token and self._broker_expires_at > time.time() + 60:
            return self._broker_token, self._broker_account_id
        response = httpx.post(
            f"{self.broker_url}/codex/oauth/broker/{self.model_id}",
            headers={"Authorization": f"Bearer {self.server_secret}", "Accept": "application/json"},
            timeout=30,
            trust_env=False,
        )
        response.raise_for_status()
        envelope = response.json()
        if envelope.get("code") != 0 or not envelope.get("data"):
            raise RuntimeError(envelope.get("msg") or "Codex OAuth token broker failed")
        data = envelope["data"]
        token = data.get("accessToken")
        account_id = data.get("accountId")
        if not token or not account_id:
            raise RuntimeError("Codex OAuth token broker returned incomplete credentials")
        self._broker_token = token
        self._broker_account_id = account_id
        self._broker_expires_at = self._parse_expiry(data.get("expiresAt"))
        return token, account_id

    @staticmethod
    def _parse_expiry(value):
        if not value:
            return time.time() + 60
        try:
            parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
            if parsed.tzinfo is None:
                parsed = parsed.replace(tzinfo=timezone.utc)
            return parsed.timestamp()
        except (TypeError, ValueError):
            return time.time() + 60

    @staticmethod
    def _response_tools(functions):
        tools = []
        for tool in functions or []:
            function = tool.get("function", tool)
            if not isinstance(function, dict) or not function.get("name"):
                raise ValueError("Codex function tools must include a function name")
            response_tool = {"type": "function", "name": function["name"]}
            for key in ("description", "parameters", "strict"):
                if key in function:
                    response_tool[key] = function[key]
            tools.append(response_tool)
        return tools

    @staticmethod
    def _request_body(dialogue, model_name, functions=None, service_tier=None):
        input_items = []
        for message in dialogue:
            role = message.get("role", "user")
            if role == "assistant" and message.get("tool_calls"):
                content = message.get("content")
                if content:
                    input_items.append({
                        "type": "message",
                        "role": "assistant",
                        "content": [{"type": "output_text", "text": str(content)}],
                    })
                for tool_call in message["tool_calls"]:
                    function = tool_call.get("function", {})
                    call_id = tool_call.get("id")
                    name = function.get("name")
                    if not call_id or not name:
                        raise ValueError("Codex function-call history is missing its id or name")
                    arguments = function.get("arguments", "{}")
                    if not isinstance(arguments, str):
                        arguments = json.dumps(arguments, ensure_ascii=False)
                    input_items.append({
                        "type": "function_call",
                        "call_id": call_id,
                        "name": name,
                        "arguments": arguments,
                    })
                continue
            if role == "tool":
                call_id = message.get("tool_call_id")
                if not call_id:
                    raise ValueError("Codex function result is missing its tool_call_id")
                input_items.append({
                    "type": "function_call_output",
                    "call_id": call_id,
                    "output": str(message.get("content", "")),
                })
                continue
            content = message.get("content", "")
            if role == "system":
                role = "developer"
            if role not in ("user", "assistant", "developer"):
                role = "user"
            content_type = "output_text" if role == "assistant" else "input_text"
            input_items.append({
                "type": "message",
                "role": role,
                "content": [{"type": content_type, "text": str(content)}],
            })
        body = {
            "model": model_name,
            "stream": True,
            "input": input_items,
            "tools": LLMProvider._response_tools(functions),
            "tool_choice": "auto",
            "parallel_tool_calls": False,
            "reasoning": None,
            "store": False,
            "include": [],
        }
        if service_tier and service_tier != "standard":
            # Codex config calls this Fast; the Responses API wire value is `priority`.
            body["service_tier"] = "priority" if service_tier == "fast" else service_tier
        return body

    def _stream(self, dialogue, model_name, functions=None, with_functions=False):
        token, account_id = self._get_credentials()
        headers = {
            "Authorization": f"Bearer {token}",
            "ChatGPT-Account-ID": account_id,
            "Content-Type": "application/json",
            "Accept": "text/event-stream",
        }
        body = self._request_body(dialogue, model_name, functions, self.service_tier)
        with httpx.stream(
            "POST",
            self.RESPONSES_URL,
            headers=headers,
            json=body,
            timeout=httpx.Timeout(self.timeout),
            trust_env=False,
        ) as response:
            response.raise_for_status()
            for line in response.iter_lines():
                if not line or not line.startswith("data:"):
                    continue
                raw = line[5:].strip()
                if raw == "[DONE]":
                    break
                try:
                    event = json.loads(raw)
                except json.JSONDecodeError:
                    continue
                event_type = event.get("type")
                if event_type == "response.output_text.delta" and event.get("delta"):
                    text = event["delta"]
                    yield (text, None) if with_functions else text
                elif with_functions and event_type == "response.output_item.done":
                    item = event.get("item") or {}
                    if item.get("type") == "function_call":
                        name = item.get("name")
                        if not name:
                            raise RuntimeError("Codex function call omitted its name")
                        arguments = item.get("arguments", "{}")
                        if not isinstance(arguments, str):
                            arguments = json.dumps(arguments, ensure_ascii=False)
                        yield None, [SimpleNamespace(
                            id=item.get("call_id") or item.get("id"),
                            type="function",
                            function=SimpleNamespace(name=name, arguments=arguments),
                        )]
                elif event_type in ("error", "response.failed"):
                    response_data = event.get("response")
                    error = event.get("error")
                    if not error and isinstance(response_data, dict):
                        error = response_data.get("error")
                    message = error.get("message") if isinstance(error, dict) else str(error or "")
                    raise RuntimeError(message or "Codex Responses stream failed")

    def response(self, session_id, dialogue, **kwargs):
        yield from self._stream(dialogue, kwargs.get("model", self.model_name))

    def response_with_functions(self, session_id, dialogue, functions=None, **kwargs):
        yield from self._stream(
            dialogue,
            kwargs.get("model", self.model_name),
            functions=functions,
            with_functions=True,
        )
