import { CirclePlay, ListChecks, Plus } from 'lucide-react-native';

import { RoutePlaceholder } from '@/components/route-placeholder';

export default function IntervalRoute() {
  return (
    <RoutePlaceholder
      title="인터벌 설정"
      description="운동 시간, 휴식 시간, 라운드 수를 구성합니다. 프리셋은 인터벌 안에서 선택하고 새로 만들 수 있습니다."
      links={[
        { label: '인터벌 실행', href: '/timer/run', icon: CirclePlay },
        { label: '인터벌 프리셋', href: '/presets', icon: ListChecks },
        { label: '새 프리셋 만들기', href: '/presets/new', icon: Plus },
      ]}
    />
  );
}
