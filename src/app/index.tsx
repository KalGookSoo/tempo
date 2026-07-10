import { RoutePlaceholder } from '@/components/route-placeholder';

export default function TimerHomeRoute() {
  return (
    <RoutePlaceholder
      title="타이머 홈"
      description="빠른 타이머 선택, 최근 설정 실행, 프리셋 진입을 담당하는 첫 화면입니다."
      links={[
        { label: '카운트다운', href: '/timer/countdown' },
        { label: '카운트업', href: '/timer/count-up' },
        { label: '스톱워치', href: '/timer/stopwatch' },
        { label: '인터벌', href: '/timer/interval' },
        { label: '프리셋', href: '/presets' },
        { label: '설정', href: '/settings' },
      ]}
    />
  );
}
