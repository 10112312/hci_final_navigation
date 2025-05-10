from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException
from app.api import auth, tesla, weather, community, range_anxiety
from app.core.logging import setup_logging
from app.core.middleware import (
    error_handler_middleware,
    validation_exception_handler,
    http_exception_handler
)
import logging

# 设置日志
setup_logging()
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Tesla Navigation API",
    description="API for Tesla Navigation application",
    version="1.0.0"
)

# 配置CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 在生产环境中应该设置具体的域名
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 添加错误处理中间件
app.middleware("http")(error_handler_middleware)
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(HTTPException, http_exception_handler)

# 注册路由
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(tesla.router, prefix="/api/tesla", tags=["Tesla"])
app.include_router(weather.router, prefix="/api/weather", tags=["Weather"])
app.include_router(community.router, prefix="/api/community", tags=["Community"])
app.include_router(range_anxiety.router, prefix="/api/range-anxiety", tags=["Range Anxiety"])

@app.on_event("startup")
async def startup_event():
    logger.info("Starting up Tesla Navigation API")

@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Shutting down Tesla Navigation API")

@app.get("/")
async def root():
    logger.info("Root endpoint accessed")
    return {"message": "Welcome to Tesla Navigation API"} 