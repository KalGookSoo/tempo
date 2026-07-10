import { RoutePlaceholder } from '@/components/route-placeholder';

export default function IntervalRoute() {
  return (
    <RoutePlaceholder
      title="인터벌 설정"
      description="운동 시간, 휴식 시간, 라운드 수를 구성하고 실행하거나 프리셋으로 저장합니다."
      links={[
        { label: '실행 화면으로 이동', href: '/timer/run' },
        { label: '프리셋으로 저장', href: '/presets/new' },
      ]}
    />
  );
}
