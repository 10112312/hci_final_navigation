from typing import Dict, Any, List
import numpy as np

class RangeAnxietyService:
    def __init__(self):
        # 不同车型的基础效率系数
        self.model_efficiency = {
            "Model Y": 1.0,  # 基准效率
            "Model 3": 0.95,
            "Model S": 1.1,
            "Model X": 1.2
        }

    def calculate_range_anxiety(self,
                              vehicle_data: Dict[str, Any],
                              weather_data: Dict[str, Any],
                              route_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        计算续航焦虑指数
        """
        # 基础参数
        battery_capacity = vehicle_data.get("battery_capacity", 0)
        current_charge = vehicle_data.get("current_charge", 0)
        max_range = vehicle_data.get("max_range", 0)
        model_type = vehicle_data.get("model_type", "Model Y")
        passengers = vehicle_data.get("passengers", 1)
        cargo_weight = vehicle_data.get("cargo_weight", 0)
        distance = route_data.get("distance", 0)
        elevation_change = route_data.get("elevation_change", 0)

        # 计算基础消耗
        base_consumption = self._calculate_base_consumption(
            distance, max_range, battery_capacity
        )

        # 计算环境因素影响
        weather_impact = self._calculate_weather_impact(weather_data)

        # 计算负载影响
        load_impact = self._calculate_load_impact(passengers, cargo_weight)

        # 计算地形影响
        terrain_impact = self._calculate_terrain_impact(elevation_change)

        # 计算车型效率影响
        model_impact = self.model_efficiency.get(model_type, 1.0)

        # 计算总消耗
        total_consumption = (
            base_consumption *
            (1 + weather_impact) *
            (1 + load_impact) *
            (1 + terrain_impact) *
            model_impact
        )

        # 计算剩余电量百分比
        remaining_percentage = (current_charge - total_consumption) / battery_capacity * 100

        # 计算焦虑指数 (0-100)
        anxiety_index = self._calculate_anxiety_index(
            remaining_percentage,
            distance,
            max_range
        )

        return {
            "anxiety_index": anxiety_index,
            "remaining_percentage": remaining_percentage,
            "total_consumption": total_consumption,
            "weather_impact": weather_impact,
            "load_impact": load_impact,
            "terrain_impact": terrain_impact,
            "model_impact": model_impact,
            "needs_charging": remaining_percentage < 20
        }

    def _calculate_base_consumption(self, distance: float, max_range: float, battery_capacity: float) -> float:
        """计算基础电量消耗"""
        return (distance / max_range) * battery_capacity

    def _calculate_weather_impact(self, weather_data: Dict[str, Any]) -> float:
        """计算天气影响"""
        temp = weather_data.get("temp", 20)
        humidity = weather_data.get("humidity", 50)
        wind_speed = weather_data.get("wind_speed", 0)

        impact = 0.0
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

        return impact

    def _calculate_load_impact(self, passengers: int, cargo_weight: float) -> float:
        """计算负载影响"""
        passenger_impact = (passengers - 1) * 0.05
        cargo_impact = (cargo_weight / 100) * 0.1
        return passenger_impact + cargo_impact

    def _calculate_terrain_impact(self, elevation_change: float) -> float:
        """计算地形影响"""
        return abs(elevation_change) * 0.001

    def _calculate_anxiety_index(self, remaining_percentage: float, distance: float, max_range: float) -> float:
        """计算焦虑指数"""
        # 基于剩余电量和距离计算基础焦虑
        base_anxiety = 100 * (1 - (remaining_percentage / 100))
        
        # 如果剩余电量不足以到达目的地，增加焦虑
        if remaining_percentage < (distance / max_range * 100):
            base_anxiety += 30

        # 如果剩余电量低于20%，显著增加焦虑
        if remaining_percentage < 20:
            base_anxiety += 40

        return min(base_anxiety, 100) 