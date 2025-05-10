import os
import aiohttp
from typing import Dict, Any
from dotenv import load_dotenv

load_dotenv()

class WeatherService:
    def __init__(self):
        self.api_key = os.getenv("OPENWEATHER_API_KEY")
        self.base_url = "https://api.openweathermap.org/data/2.5"

    async def get_weather(self, lat: float, lon: float) -> Dict[str, Any]:
        """获取特定位置的天气数据"""
        url = f"{self.base_url}/weather"
        params = {
            "lat": lat,
            "lon": lon,
            "appid": self.api_key,
            "units": "metric"
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.get(url, params=params) as response:
                if response.status == 200:
                    return await response.json()
                return {}

    async def get_weather_forecast(self, lat: float, lon: float) -> Dict[str, Any]:
        """获取天气预报数据"""
        url = f"{self.base_url}/forecast"
        params = {
            "lat": lat,
            "lon": lon,
            "appid": self.api_key,
            "units": "metric"
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.get(url, params=params) as response:
                if response.status == 200:
                    return await response.json()
                return {}

    def calculate_weather_impact(self, weather_data: Dict[str, Any]) -> float:
        """
        计算天气对电动车续航的影响
        返回一个影响系数（0-1之间，1表示最大影响）
        """
        if not weather_data:
            return 0.0

        impact = 0.0
        temp = weather_data.get("main", {}).get("temp", 20)
        humidity = weather_data.get("main", {}).get("humidity", 50)
        wind_speed = weather_data.get("wind", {}).get("speed", 0)

        # 温度影响
        if temp < 0:
            impact += 0.3
        elif temp < 10:
            impact += 0.2
        elif temp > 30:
            impact += 0.15

        # 湿度影响
        if humidity > 80:
            impact += 0.1

        # 风速影响
        if wind_speed > 20:
            impact += 0.2
        elif wind_speed > 10:
            impact += 0.1

        return min(impact, 1.0) 