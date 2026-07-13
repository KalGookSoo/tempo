import { useLocalSearchParams } from 'expo-router';

import { RoutePlaceholder } from '@/components/route-placeholder';

export default function CustomPresetDetailRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();

  return (
    <RoutePlaceholder
      title={`사용자 프리셋: ${id ?? ''}`}
      description="사용자가 만든 프리셋을 실행, 편집, 복제, 삭제합니다."
      links={[
        { label: '실행 화면으로 이동', href: '/interval/run' },
        { label: '프리셋 편집', href: `/interval/presets/custom/${id ?? ''}/edit` },
      ]}
    />
  );
}
