import { RoutePlaceholder } from '@/components/route-placeholder';

export default function CountdownRoute() {
  return (
    <RoutePlaceholder
      title="카운트다운 설정"
      description="시작 시간을 입력하고 준비 카운트다운과 알림 큐를 확인한 뒤 실행 화면으로 이동합니다."
      links={[
        { label: '실행 화면으로 이동', href: '/timer/run' },
        { label: '프리셋으로 저장', href: '/presets/new' },
      ]}
    />
  );
}
