import { Repeat, Timer, TimerReset, TrendingUp } from 'lucide-react-native';

import { RoutePlaceholder } from '@/components/route-placeholder';

export default function TimerHomeRoute() {
  return (
    <RoutePlaceholder
      title="타이머 홈"
      description="운동 중 바로 실행할 수 있는 핵심 타이머만 모아둔 첫 화면입니다."
      links={[
        { label: '카운트다운', href: '/timer/countdown', icon: Timer },
        { label: '카운트업', href: '/timer/count-up', icon: TrendingUp },
        { label: '스톱워치', href: '/timer/stopwatch', icon: TimerReset },
        { label: '인터벌', href: '/timer/interval', icon: Repeat },
      ]}
    />
  );
}
