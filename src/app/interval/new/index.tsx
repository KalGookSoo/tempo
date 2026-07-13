import { CirclePlay, Save } from 'lucide-react-native';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Button, Card, Heading, Paragraph } from '@/components/ui';
import { MaxContentWidth, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

const steps = [
  {
    title: '1. 프로그램 이름',
    description: '예: Tabata 변형, 하체 EMOM, 파이트 곤 배드 스타일처럼 알아보기 쉬운 이름을 붙입니다.',
  },
  {
    title: '2. 구간 구성',
    description: '운동, 휴식, 준비 시간을 순서대로 구성합니다. 여러 구간을 조합해 하나의 세트를 만듭니다.',
  },
  {
    title: '3. 라운드',
    description: '구성한 세트를 몇 번 반복할지 정합니다. 필요하면 세트 사이 휴식도 추가합니다.',
  },
  {
    title: '4. 알림 큐',
    description: '시작, 종료, 전환 시점에 사용할 소리나 진동 규칙을 선택합니다.',
  },
];

export default function NewIntervalProgramRoute() {
  const router = useRouter();
  const theme = useTheme();

  return (
    <ScrollView style={[styles.screen, { backgroundColor: theme.background }]}>
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.container}>
          <View style={styles.header}>
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

            <Button icon={Save} size="sm" style={styles.saveButton} onPress={() => router.push('/interval/presets')}>
              저장
            </Button>
          </View>

          <Card>
            <Heading>새 프로그램</Heading>
            <Paragraph muted>인터벌 프로그램을 단계적으로 구성한 뒤 저장하거나 바로 실행합니다.</Paragraph>
          </Card>

          <View style={styles.steps}>
            {steps.map((step) => (
              <Card key={step.title}>
                <Heading level={3}>{step.title}</Heading>
                <Paragraph muted>{step.description}</Paragraph>
              </Card>
            ))}
          </View>

          <Button icon={CirclePlay} size="lg" onPress={() => router.push('/interval/run')}>
            최종 실행
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
  header: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: '100%',
  },
  backButton: {
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
  saveButton: {
    minWidth: 96,
  },
  steps: {
    gap: Spacing.three,
  },
  pressed: {
    opacity: 0.75,
    transform: [{ translateX: 1 }, { translateY: 1 }],
  },
});
