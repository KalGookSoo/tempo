import { useLocalSearchParams } from 'expo-router';

import { RoutePlaceholder } from '@/components/route-placeholder';

export default function DefaultPresetDetailRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();

  return (
    <RoutePlaceholder
      title={`기본 프리셋: ${id ?? ''}`}
      description="기본 프리셋 설정을 확인하고 바로 실행하거나 복제해서 사용자 프리셋으로 저장합니다."
      links={[
        { label: '실행 화면으로 이동', href: '/timer/run' },
        { label: '복제 후 편집', href: `/presets/new?from=${id ?? ''}` },
      ]}
    />
  );
}
