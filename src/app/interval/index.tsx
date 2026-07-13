import { CircleHelp, ListChecks, Plus } from 'lucide-react-native';

import { RoutePlaceholder } from '@/components/route-placeholder';

export default function IntervalRoute() {
  return (
    <RoutePlaceholder
      title="인터벌"
      description="운동 시간, 휴식 시간, 라운드 수를 조합해 반복 프로그램을 구성합니다."
      links={[
        { label: '새 프로그램', href: '/interval/new', icon: Plus },
        { label: '프리셋', href: '/interval/presets', icon: ListChecks },
        { label: '도움말', href: '/interval/help', icon: CircleHelp },
      ]}
    />
  );
}
