import { Repeat, Timer, TimerReset } from 'lucide-react-native';

import { RoutePlaceholder } from '@/components/route-placeholder';

export default function TimerHomeRoute() {
  return (
    <RoutePlaceholder
      title="타이머 홈"
      description="운동 중 바로 실행할 수 있는 핵심 타이머만 모아둔 첫 화면입니다."
      links={[
        { label: '타이머', href: '/timer', icon: Timer },
        { label: '스톱워치', href: '/stopwatch', icon: TimerReset },
        { label: '인터벌', href: '/interval', icon: Repeat },
      ]}
    />
  );
}
