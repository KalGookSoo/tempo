import { RoutePlaceholder } from '@/components/route-placeholder';

export default function TimerRunRoute() {
  return (
    <RoutePlaceholder
      title="실행 화면"
      description="큰 시간 숫자, 현재 구간, 라운드 정보를 표시합니다. 미러링을 고려한 핵심 화면입니다."
      links={[
        { label: '타이머 홈으로 이동', href: '/' },
        { label: '인터벌로 돌아가기', href: '/interval' },
      ]}
    />
  );
}
