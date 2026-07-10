import { RoutePlaceholder } from '@/components/route-placeholder';

export default function SettingsRoute() {
  return (
    <RoutePlaceholder
      title="설정"
      description="알림 큐, 표시 설정, 사운드와 녹음 관리로 이동합니다."
      links={[
        { label: '알림 큐', href: '/settings/notification-cues' },
        { label: '표시 설정', href: '/settings/display' },
        { label: '사운드/녹음 관리', href: '/settings/sounds' },
      ]}
    />
  );
}
