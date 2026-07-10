import { RoutePlaceholder } from '@/components/route-placeholder';

export default function NewPresetRoute() {
  return (
    <RoutePlaceholder
      title="새 프리셋 만들기"
      description="이름, 인터벌 세트, 라운드, 알림 큐를 설정해 사용자 프리셋을 만듭니다."
      links={[
        { label: '프리셋 목록으로 이동', href: '/presets' },
        { label: '저장 후 실행 예시', href: '/timer/run' },
      ]}
    />
  );
}
