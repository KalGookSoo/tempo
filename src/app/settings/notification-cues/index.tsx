import { RoutePlaceholder } from '@/components/route-placeholder';

export default function NotificationCuesRoute() {
  return (
    <RoutePlaceholder
      title="알림 큐"
      description="사운드, 진동, 시작 전 알림 시점, 이벤트별 알림을 설정합니다."
      links={[{ label: '설정 홈으로 이동', href: '/settings' }]}
    />
  );
}
