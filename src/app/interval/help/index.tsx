import { Plus } from 'lucide-react-native';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Button, Card, Heading, Paragraph } from '@/components/ui';
import { MaxContentWidth, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

const guides = [
  {
    title: 'Tabata',
    description: '보통 20초 운동, 10초 휴식을 8라운드 반복하는 짧고 강한 인터벌입니다.',
  },
  {
    title: 'EMOM',
    description: 'Every Minute On the Minute의 약자입니다. 매 분마다 정해진 동작을 시작하고 남은 시간은 휴식합니다.',
  },
  {
    title: 'FGB 스타일',
    description: '여러 운동 구간을 연속으로 돌고 라운드 사이에 긴 휴식을 두는 방식입니다.',
  },
  {
    title: '직접 만들기',
    description: '운동, 휴식, 준비, 라운드, 알림 큐를 순서대로 정하면 대부분의 인터벌 프로그램을 만들 수 있습니다.',
  },
];

export default function IntervalHelpRoute() {
  const router = useRouter();
  const theme = useTheme();

  return (
    <ScrollView style={[styles.screen, { backgroundColor: theme.background }]}>
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.container}>
          <Pressable
            accessibilityRole="button"
            onPress={() => (router.canGoBack() ? router.back() : router.replace('/interval'))}
            style={({ pressed }) => [
              styles.backButton,
              { backgroundColor: theme.surface, borderColor: theme.border },
              pressed && styles.pressed,
            ]}>
            <Text style={[styles.backButtonText, { color: theme.text }]}>← 뒤로</Text>
          </Pressable>

          <Card>
            <Heading>인터벌 도움말</Heading>
            <Paragraph muted>자주 쓰는 운동 프로그램을 tempo 인터벌로 바꾸는 방법입니다.</Paragraph>
          </Card>

          <View style={styles.guides}>
            {guides.map((guide) => (
              <Card key={guide.title}>
                <Heading level={3}>{guide.title}</Heading>
                <Paragraph muted>{guide.description}</Paragraph>
              </Card>
            ))}
          </View>

          <Button icon={Plus} size="lg" onPress={() => router.push('/interval/new')}>
            새 프로그램 만들기
          </Button>
        </View>
      </SafeAreaView>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
  },
  safeArea: {
    alignItems: 'center',
    flex: 1,
    paddingBottom: Spacing.three,
    paddingHorizontal: Spacing.four,
    paddingTop: Spacing.four,
  },
  container: {
    gap: Spacing.four,
    maxWidth: MaxContentWidth,
    width: '100%',
  },
  backButton: {
    alignSelf: 'flex-start',
    borderRadius: 4,
    borderWidth: 3,
    paddingHorizontal: Spacing.three,
    paddingVertical: Spacing.two,
  },
  backButtonText: {
    fontSize: 16,
    fontWeight: '900',
    lineHeight: 20,
  },
  guides: {
    gap: Spacing.three,
  },
  pressed: {
    opacity: 0.75,
    transform: [{ translateX: 1 }, { translateY: 1 }],
  },
});
