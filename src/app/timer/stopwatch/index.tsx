import { RoutePlaceholder } from '@/components/route-placeholder';

export default function StopwatchRoute() {
  return (
    <RoutePlaceholder
      title="스톱워치"
      description="준비 카운트다운 없이 00:00.00부터 경과 시간을 측정합니다."
      links={[{ label: '타이머 홈으로 이동', href: '/' }]}
    />
  );
}
