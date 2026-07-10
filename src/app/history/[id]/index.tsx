import { useLocalSearchParams } from 'expo-router';

import { RoutePlaceholder } from '@/components/route-placeholder';

export default function HistoryDetailRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();

  return (
    <RoutePlaceholder
      title={`기록 상세: ${id ?? ''}`}
      description="실행했던 타이머 설정과 결과를 확인하고 다시 실행하거나 프리셋으로 저장합니다."
      links={[
        { label: '다시 실행', href: '/timer/run' },
        { label: '프리셋으로 저장', href: `/presets/new?fromHistory=${id ?? ''}` },
      ]}
    />
  );
}
