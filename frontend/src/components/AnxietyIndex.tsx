import React from 'react';

interface AnxietyIndexProps {
    anxietyLevel: number; // 0-100 的焦虑指数
    batteryLevel: number; // 当前电量百分比
    estimatedRange: number; // 预估续航里程
    distanceToDestination: number; // 到目的地的距离
}

const AnxietyIndex: React.FC<AnxietyIndexProps> = ({
    anxietyLevel,
    batteryLevel,
    estimatedRange,
    distanceToDestination
}) => {
    // 根据焦虑指数获取表情和颜色
    const getAnxietyInfo = (level: number) => {
        if (level <= 20) {
            return {
                emoji: '😊',
                color: 'text-green-500',
                bgColor: 'bg-green-100',
                text: '非常安心'
            };
        } else if (level <= 40) {
            return {
                emoji: '🙂',
                color: 'text-green-400',
                bgColor: 'bg-green-50',
                text: '比较安心'
            };
        } else if (level <= 60) {
            return {
                emoji: '😐',
                color: 'text-yellow-500',
                bgColor: 'bg-yellow-100',
                text: '略有担忧'
            };
        } else if (level <= 80) {
            return {
                emoji: '😟',
                color: 'text-orange-500',
                bgColor: 'bg-orange-100',
                text: '比较焦虑'
            };
        } else {
            return {
                emoji: '😰',
                color: 'text-red-500',
                bgColor: 'bg-red-100',
                text: '非常焦虑'
            };
        }
    };

    const anxietyInfo = getAnxietyInfo(anxietyLevel);

    return (
        <div className={`p-4 rounded-lg ${anxietyInfo.bgColor} shadow-md`}>
            <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold">焦虑指数</h3>
                <span className="text-3xl">{anxietyInfo.emoji}</span>
            </div>
            
            <div className="mb-4">
                <div className="flex justify-between mb-2">
                    <span className="text-sm text-gray-600">焦虑程度</span>
                    <span className={`font-medium ${anxietyInfo.color}`}>
                        {anxietyInfo.text}
                    </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2.5">
                    <div
                        className={`h-2.5 rounded-full ${anxietyInfo.color.replace('text', 'bg')}`}
                        style={{ width: `${anxietyLevel}%` }}
                    ></div>
                </div>
            </div>

            <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                    <span className="text-gray-600">当前电量</span>
                    <span className="font-medium">{batteryLevel}%</span>
                </div>
                <div className="flex justify-between">
                    <span className="text-gray-600">预估续航</span>
                    <span className="font-medium">{estimatedRange} 公里</span>
                </div>
                <div className="flex justify-between">
                    <span className="text-gray-600">目的地距离</span>
                    <span className="font-medium">{distanceToDestination} 公里</span>
                </div>
            </div>

            <div className="mt-4 text-sm text-gray-600">
                <p className="font-medium mb-1">焦虑指数说明：</p>
                <p>焦虑指数是根据当前电量、预估续航里程和目的地距离综合计算得出的指标。</p>
                <p>0-20: 电量充足，无需担心</p>
                <p>21-40: 电量较为充足，建议关注</p>
                <p>41-60: 电量适中，需要规划充电</p>
                <p>61-80: 电量偏低，建议尽快充电</p>
                <p>81-100: 电量严重不足，需要立即充电</p>
            </div>
        </div>
    );
};

export default AnxietyIndex; 