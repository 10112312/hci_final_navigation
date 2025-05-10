from typing import Dict, Any, Optional
from datetime import datetime, timedelta
import jwt
from passlib.context import CryptContext
import uuid

class AuthService:
    def __init__(self):
        self.pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
        self.secret_key = "your-secret-key"  # 在生产环境中应该使用环境变量
        self.algorithm = "HS256"
        self.access_token_expire_minutes = 30
        
        # 模拟用户数据库
        self.users = {}

    def create_user(self, email: str, password: str, username: str) -> Dict[str, Any]:
        """创建新用户"""
        if email in self.users:
            return {"error": "Email already registered"}

        user_id = str(uuid.uuid4())
        hashed_password = self.pwd_context.hash(password)
        
        user = {
            "id": user_id,
            "email": email,
            "username": username,
            "hashed_password": hashed_password,
            "created_at": datetime.utcnow().isoformat(),
            "is_active": True
        }
        
        self.users[email] = user
        return {"id": user_id, "email": email, "username": username}

    def authenticate_user(self, email: str, password: str) -> Optional[Dict[str, Any]]:
        """验证用户"""
        user = self.users.get(email)
        if not user:
            return None
        if not self.pwd_context.verify(password, user["hashed_password"]):
            return None
        return user

    def create_access_token(self, user: Dict[str, Any]) -> str:
        """创建访问令牌"""
        expire = datetime.utcnow() + timedelta(minutes=self.access_token_expire_minutes)
        to_encode = {
            "sub": user["id"],
            "email": user["email"],
            "exp": expire
        }
        return jwt.encode(to_encode, self.secret_key, algorithm=self.algorithm)

    def verify_token(self, token: str) -> Optional[Dict[str, Any]]:
        """验证令牌"""
        try:
            payload = jwt.decode(token, self.secret_key, algorithms=[self.algorithm])
            user_id = payload.get("sub")
            if user_id is None:
                return None
            return self.get_user_by_id(user_id)
        except jwt.PyJWTError:
            return None

    def get_user_by_id(self, user_id: str) -> Optional[Dict[str, Any]]:
        """通过ID获取用户"""
        for user in self.users.values():
            if user["id"] == user_id:
                return user
        return None

    def update_user_profile(self, user_id: str, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """更新用户资料"""
        user = self.get_user_by_id(user_id)
        if not user:
            return None

        # 更新允许的字段
        allowed_fields = ["username", "email"]
        for field in allowed_fields:
            if field in data:
                user[field] = data[field]

        return user

    def change_password(self, user_id: str, current_password: str, new_password: str) -> bool:
        """更改密码"""
        user = self.get_user_by_id(user_id)
        if not user:
            return False

        if not self.pwd_context.verify(current_password, user["hashed_password"]):
            return False

        user["hashed_password"] = self.pwd_context.hash(new_password)
        return True 