import { RoutePlaceholder } from '@/components/route-placeholder';

export default function CountUpRoute() {
  return (
    <RoutePlaceholder
      title="카운트업 설정"
      description="00:00에서 시작해 설정한 종료 시간까지 증가하는 타이머를 준비합니다."
      links={[
        { label: '실행 화면으로 이동', href: '/timer/run' },
        { label: '프리셋으로 저장', href: '/presets/new' },
      ]}
    />
  );
}
