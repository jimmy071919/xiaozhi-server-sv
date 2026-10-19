package xiaozhi.modules.codex.dao;

import org.apache.ibatis.annotations.Mapper;

import xiaozhi.common.dao.BaseDao;
import xiaozhi.modules.codex.entity.CodexOAuthCredentialEntity;

@Mapper
public interface CodexOAuthCredentialDao extends BaseDao<CodexOAuthCredentialEntity> {
}
