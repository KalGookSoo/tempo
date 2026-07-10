import { RoutePlaceholder } from '@/components/route-placeholder';

export default function PresetsRoute() {
  return (
    <RoutePlaceholder
      title="프리셋"
      description="기본 제공 프리셋과 사용자가 만든 프리셋을 관리합니다."
      links={[
        { label: '새 프리셋 만들기', href: '/presets/new' },
        { label: 'Tabata 상세 예시', href: '/presets/default/tabata' },
        { label: '사용자 프리셋 상세 예시', href: '/presets/custom/example' },
      ]}
    />
  );
}
