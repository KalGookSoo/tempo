import { useLocalSearchParams } from 'expo-router';

import { RoutePlaceholder } from '@/components/route-placeholder';

export default function CustomPresetEditRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();

  return (
    <RoutePlaceholder
      title={`프리셋 편집: ${id ?? ''}`}
      description="이름, 인터벌 세트, 라운드, 알림 큐를 수정합니다."
      links={[
        { label: '프리셋 상세로 이동', href: `/interval/presets/custom/${id ?? ''}` },
        { label: '실행 화면으로 이동', href: '/interval/run' },
      ]}
    />
  );
}
