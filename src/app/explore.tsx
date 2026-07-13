import { RoutePlaceholder } from '@/components/route-placeholder';

export default function ExploreRoute() {
  return (
    <RoutePlaceholder
      title="개발 허브"
      description="Expo 템플릿 안내 대신 tempo 문서와 주요 화면을 확인하기 위한 임시 페이지입니다."
      links={[
        { label: '타이머 홈', href: '/' },
        { label: '프리셋', href: '/presets' },
        { label: '설정', href: '/settings' },
      ]}
    />
  );
}
