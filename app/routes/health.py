"""GET /api/health — 서버 상태, MOCK 여부, 모델 설정.
GET /health — 프론트(Flutter) 연결 테스트용 짧은 응답 (HEALTH_CHECK_PATH 기본값)."""
from fastapi import APIRouter, Depends

from ..config import Settings
from ..deps import get_settings

router = APIRouter(prefix="/api", tags=["health"])
root_router = APIRouter(tags=["health"])


@router.get("/health")
async def health(settings: Settings = Depends(get_settings)):
    # 키 값 자체는 절대 내보내지 않음
    return {
        "ok": True,
        "mock": settings.mock,
        "mock_reason": settings.mock_reason,
        "api_key_configured": bool(settings.api_key),
        "models": {
            "analysis": settings.model_analysis,
            "vision": settings.model_vision,
            "light": settings.model_light,
        },
        "customize_dir_exists": settings.customize_dir.is_dir(),
    }


@root_router.get("/health")
async def frontend_health(settings: Settings = Depends(get_settings)):
    return {"status": "ok", "mock": settings.mock}
