import { RoutePlaceholder } from '@/components/route-placeholder';

export default function SoundsSettingsRoute() {
  return (
    <RoutePlaceholder
      title="사운드/녹음 관리"
      description="기본 사운드, 음원 파일, 직접 녹음 음성 큐를 관리하는 화면입니다."
      links={[{ label: '설정 홈으로 이동', href: '/settings' }]}
    />
  );
}
