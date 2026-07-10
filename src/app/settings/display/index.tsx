import { RoutePlaceholder } from '@/components/route-placeholder';

export default function DisplaySettingsRoute() {
  return (
    <RoutePlaceholder
      title="표시 설정"
      description="라이트/다크 모드, 타이머 화면 대비, 미러링 화면 표시 방식을 조정합니다."
      links={[{ label: '설정 홈으로 이동', href: '/settings' }]}
    />
  );
}
