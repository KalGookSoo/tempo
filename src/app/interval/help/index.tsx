import { ListChecks, Plus } from 'lucide-react-native';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Button, Card, Heading, Paragraph } from '@/components/ui';
import { MaxContentWidth, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { intervalHelpGuides } from '@/lib/interval-help';

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
            {intervalHelpGuides.map((guide) => (
              <Button
                key={guide.id}
                icon={ListChecks}
                variant="secondary"
                onPress={() => router.push(`/interval/help/${guide.id}` as never)}>
                {guide.title}
              </Button>
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
