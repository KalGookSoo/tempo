import { Plus } from 'lucide-react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Button, Card, Heading, OrderedList, Paragraph } from '@/components/ui';
import { MaxContentWidth, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { getIntervalHelpGuide } from '@/lib/interval-help';

export default function IntervalHelpDetailRoute() {
  const router = useRouter();
  const theme = useTheme();
  const { id } = useLocalSearchParams<{ id: string }>();
  const guideId = Array.isArray(id) ? id[0] : id;
  const guide = guideId ? getIntervalHelpGuide(guideId) : null;

  return (
    <ScrollView style={[styles.screen, { backgroundColor: theme.background }]}>
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.container}>
          <Pressable
            accessibilityRole="button"
            onPress={() => router.replace('/interval/help')}
            style={({ pressed }) => [
              styles.backButton,
              { backgroundColor: theme.surface, borderColor: theme.border },
              pressed && styles.pressed,
            ]}>
            <Text style={[styles.backButtonText, { color: theme.text }]}>← 목록으로가기</Text>
          </Pressable>

          {guide ? (
            <>
              <Card>
                <Heading>{guide.title}</Heading>
                <Paragraph muted>{guide.description}</Paragraph>
              </Card>

              <Card>
                <Heading level={2}>템포에서 만드는 방법</Heading>
                <OrderedList items={guide.steps} />
              </Card>

              {guide.customNote ? (
                <Card tone="primary">
                  <Heading level={3} style={styles.primaryCardText}>참고</Heading>
                  <Paragraph style={styles.primaryCardText}>{guide.customNote}</Paragraph>
                </Card>
              ) : null}

              <Button icon={Plus} size="lg" onPress={() => router.push('/interval/new')}>
                새 프로그램 만들기
              </Button>
            </>
          ) : (
            <Card>
              <Heading>도움말을 찾을 수 없습니다</Heading>
              <Paragraph muted>목록으로 돌아가 다른 도움말을 선택하세요.</Paragraph>
            </Card>
          )}
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
  primaryCardText: {
    color: '#111111',
  },
  pressed: {
    opacity: 0.75,
    transform: [{ translateX: 1 }, { translateY: 1 }],
  },
});
