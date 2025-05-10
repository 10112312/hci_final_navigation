from typing import List, Dict, Any
from datetime import datetime
import uuid

class CommunityService:
    def __init__(self):
        # 模拟数据库
        self.posts = {}
        self.comments = {}
        self.likes = {}

    def create_post(self, user_id: str, content: str, title: str) -> Dict[str, Any]:
        """创建新帖子"""
        post_id = str(uuid.uuid4())
        post = {
            "id": post_id,
            "user_id": user_id,
            "title": title,
            "content": content,
            "created_at": datetime.utcnow().isoformat(),
            "likes_count": 0,
            "comments_count": 0
        }
        self.posts[post_id] = post
        return post

    def get_post(self, post_id: str) -> Dict[str, Any]:
        """获取帖子详情"""
        return self.posts.get(post_id, {})

    def get_all_posts(self) -> List[Dict[str, Any]]:
        """获取所有帖子"""
        return list(self.posts.values())

    def like_post(self, post_id: str, user_id: str) -> Dict[str, Any]:
        """点赞帖子"""
        if post_id not in self.posts:
            return {"error": "Post not found"}

        like_key = f"{post_id}:{user_id}"
        if like_key in self.likes:
            # 取消点赞
            del self.likes[like_key]
            self.posts[post_id]["likes_count"] -= 1
        else:
            # 添加点赞
            self.likes[like_key] = {
                "post_id": post_id,
                "user_id": user_id,
                "created_at": datetime.utcnow().isoformat()
            }
            self.posts[post_id]["likes_count"] += 1

        return self.posts[post_id]

    def add_comment(self, post_id: str, user_id: str, content: str) -> Dict[str, Any]:
        """添加评论"""
        if post_id not in self.posts:
            return {"error": "Post not found"}

        comment_id = str(uuid.uuid4())
        comment = {
            "id": comment_id,
            "post_id": post_id,
            "user_id": user_id,
            "content": content,
            "created_at": datetime.utcnow().isoformat()
        }
        self.comments[comment_id] = comment
        self.posts[post_id]["comments_count"] += 1

        return comment

    def get_comments(self, post_id: str) -> List[Dict[str, Any]]:
        """获取帖子的所有评论"""
        return [comment for comment in self.comments.values() if comment["post_id"] == post_id]

    def delete_post(self, post_id: str, user_id: str) -> bool:
        """删除帖子"""
        if post_id not in self.posts:
            return False

        post = self.posts[post_id]
        if post["user_id"] != user_id:
            return False

        # 删除相关的评论和点赞
        self.comments = {k: v for k, v in self.comments.items() if v["post_id"] != post_id}
        self.likes = {k: v for k, v in self.likes.items() if v["post_id"] != post_id}
        del self.posts[post_id]

        return True 