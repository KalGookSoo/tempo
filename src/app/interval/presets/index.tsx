import { RoutePlaceholder } from '@/components/route-placeholder';

export default function PresetsRoute() {
  return (
    <RoutePlaceholder
      title="프리셋"
      description="인터벌 프로그램 프리셋을 선택하거나 새 프로그램을 만듭니다."
      links={[
        { label: '새 프로그램', href: '/interval/new' },
        { label: 'Tabata 상세 예시', href: '/interval/presets/default/tabata' },
        { label: 'EMOM 상세 예시', href: '/interval/presets/default/emom' },
        { label: '사용자 프로그램 상세 예시', href: '/interval/presets/custom/example' },
      ]}
    />
  );
}
