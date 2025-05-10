interface AnxietyCalculationParams {
    batteryLevel: number; // 当前电量百分比
    estimatedRange: number; // 预估续航里程
    distanceToDestination: number; // 到目的地的距离
    weatherImpact?: number; // 天气影响因子 (0-1)
    temperature?: number; // 温度影响
    elevationChange?: number; // 海拔变化
}

export const calculateAnxietyIndex = ({
    batteryLevel,
    estimatedRange,
    distanceToDestination,
    weatherImpact = 0,
    temperature = 20,
    elevationChange = 0
}: AnxietyCalculationParams): number => {
    // 基础焦虑指数计算
    let anxietyIndex = 0;

    // 1. 电量焦虑 (权重: 40%)
    const batteryAnxiety = (100 - batteryLevel) * 0.4;

    // 2. 续航焦虑 (权重: 30%)
    const rangeRatio = distanceToDestination / estimatedRange;
    const rangeAnxiety = Math.min(100, rangeRatio * 100) * 0.3;

    // 3. 天气影响 (权重: 15%)
    const weatherAnxiety = weatherImpact * 100 * 0.15;

    // 4. 温度影响 (权重: 10%)
    const tempAnxiety = Math.abs(temperature - 20) * 0.1; // 20度是最佳温度

    // 5. 海拔变化影响 (权重: 5%)
    const elevationAnxiety = Math.abs(elevationChange) * 0.05;

    // 计算总焦虑指数
    anxietyIndex = batteryAnxiety + rangeAnxiety + weatherAnxiety + tempAnxiety + elevationAnxiety;

    // 确保焦虑指数在 0-100 之间
    return Math.min(100, Math.max(0, anxietyIndex));
};

export const getAnxietyLevel = (anxietyIndex: number): string => {
    if (anxietyIndex <= 20) return '非常安心';
    if (anxietyIndex <= 40) return '比较安心';
    if (anxietyIndex <= 60) return '略有担忧';
    if (anxietyIndex <= 80) return '比较焦虑';
    return '非常焦虑';
};

export const getAnxietyColor = (anxietyIndex: number): string => {
    if (anxietyIndex <= 20) return 'green';
    if (anxietyIndex <= 40) return 'light-green';
    if (anxietyIndex <= 60) return 'yellow';
    if (anxietyIndex <= 80) return 'orange';
    return 'red';
};

export const getAnxietyEmoji = (anxietyIndex: number): string => {
    if (anxietyIndex <= 20) return '😊';
    if (anxietyIndex <= 40) return '🙂';
    if (anxietyIndex <= 60) return '😐';
    if (anxietyIndex <= 80) return '😟';
    return '😰';
}; 