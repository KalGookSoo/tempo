import { RoutePlaceholder } from '@/components/route-placeholder';

export default function HistoryRoute() {
  return (
    <RoutePlaceholder
      title="기록"
      description="최근 실행한 타이머와 설정을 확인하고 같은 설정으로 다시 실행합니다."
      links={[
        { label: '기록 상세 예시', href: '/history/example' },
        { label: '타이머 홈으로 이동', href: '/' },
      ]}
    />
  );
}
