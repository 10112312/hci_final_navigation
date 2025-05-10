from fastapi import APIRouter, Depends, HTTPException, status
from typing import Dict, Any, List
from app.services.community_service import CommunityService
from app.services.auth_service import AuthService
from app.api.auth import oauth2_scheme

router = APIRouter()
community_service = CommunityService()
auth_service = AuthService()

@router.post("/posts")
async def create_post(
    title: str,
    content: str,
    token: str = Depends(oauth2_scheme)
) -> Dict[str, Any]:
    """创建新帖子"""
    user = auth_service.verify_token(token)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
    
    post = community_service.create_post(user["id"], content, title)
    return post

@router.get("/posts")
async def get_all_posts() -> List[Dict[str, Any]]:
    """获取所有帖子"""
    return community_service.get_all_posts()

@router.get("/posts/{post_id}")
async def get_post(post_id: str) -> Dict[str, Any]:
    """获取特定帖子"""
    post = community_service.get_post(post_id)
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    return post

@router.post("/posts/{post_id}/like")
async def like_post(
    post_id: str,
    token: str = Depends(oauth2_scheme)
) -> Dict[str, Any]:
    """点赞帖子"""
    user = auth_service.verify_token(token)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
    
    result = community_service.like_post(post_id, user["id"])
    if "error" in result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=result["error"]
        )
    return result

@router.post("/posts/{post_id}/comments")
async def add_comment(
    post_id: str,
    content: str,
    token: str = Depends(oauth2_scheme)
) -> Dict[str, Any]:
    """添加评论"""
    user = auth_service.verify_token(token)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
    
    comment = community_service.add_comment(post_id, user["id"], content)
    if "error" in comment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=comment["error"]
        )
    return comment

@router.get("/posts/{post_id}/comments")
async def get_comments(post_id: str) -> List[Dict[str, Any]]:
    """获取帖子的所有评论"""
    return community_service.get_comments(post_id)

@router.delete("/posts/{post_id}")
async def delete_post(
    post_id: str,
    token: str = Depends(oauth2_scheme)
) -> Dict[str, Any]:
    """删除帖子"""
    user = auth_service.verify_token(token)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
    
    if not community_service.delete_post(post_id, user["id"]):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found or unauthorized"
        )
    
    return {"message": "Post deleted successfully"} 