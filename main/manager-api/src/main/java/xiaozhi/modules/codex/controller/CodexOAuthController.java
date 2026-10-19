package xiaozhi.modules.codex.controller;

import org.apache.shiro.authz.annotation.RequiresPermissions;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;
import xiaozhi.common.utils.Result;
import xiaozhi.modules.codex.service.CodexOAuthService;
import xiaozhi.modules.codex.service.CodexOAuthService.BrokerToken;
import xiaozhi.modules.codex.service.CodexOAuthService.LoginStart;
import xiaozhi.modules.codex.service.CodexOAuthService.OAuthStatus;

@RestController
@RequestMapping("/codex/oauth")
@RequiredArgsConstructor
public class CodexOAuthController {
    private final CodexOAuthService service;

    @PostMapping("/{modelId}/start")
    @RequiresPermissions("sys:role:superAdmin")
    public Result<LoginStart> start(@PathVariable String modelId) {
        return new Result<LoginStart>().ok(service.start(modelId));
    }

    @PostMapping("/{modelId}/poll")
    @RequiresPermissions("sys:role:superAdmin")
    public Result<OAuthStatus> poll(@PathVariable String modelId) {
        return new Result<OAuthStatus>().ok(service.poll(modelId));
    }

    @GetMapping("/{modelId}/status")
    @RequiresPermissions("sys:role:superAdmin")
    public Result<OAuthStatus> status(@PathVariable String modelId) {
        return new Result<OAuthStatus>().ok(service.status(modelId));
    }

    @DeleteMapping("/{modelId}")
    @RequiresPermissions("sys:role:superAdmin")
    public Result<Void> logout(@PathVariable String modelId) {
        service.logout(modelId);
        return new Result<>();
    }

    @PostMapping("/broker/{modelId}")
    public Result<BrokerToken> broker(@PathVariable String modelId) {
        return new Result<BrokerToken>().ok(service.brokerToken(modelId));
    }
}
