import { CircleHelp, ListChecks, Plus } from 'lucide-react-native';
import { useCallback, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useFocusEffect, useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Button, Card, Heading, Paragraph } from '@/components/ui';
import { MaxContentWidth, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { formatDuration, listIntervalPrograms, type IntervalProgram } from '@/lib/interval-programs';

function EmptyProgramList() {
  return (
    <Card>
      <Heading level={3}>저장된 프로그램이 없습니다</Heading>
      <Paragraph muted>새 프로그램을 만들어 저장하면 이곳에 목록으로 표시됩니다.</Paragraph>
    </Card>
  );
}

export default function ProgramsRoute() {
  const router = useRouter();
  const theme = useTheme();
  const [programs, setPrograms] = useState<IntervalProgram[]>([]);

  useFocusEffect(
    useCallback(() => {
      let mounted = true;

      void listIntervalPrograms().then((nextPrograms) => {
        if (mounted) {
          setPrograms(nextPrograms);
        }
      });

      return () => {
        mounted = false;
      };
    }, []),
  );

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
            <Heading>프로그램 목록</Heading>
            <Paragraph muted>저장한 인터벌 프로그램을 선택하거나 새 프로그램을 만듭니다.</Paragraph>
          </Card>

          <View style={styles.actions}>
            <Button icon={Plus} size="lg" style={styles.actionButton} onPress={() => router.push('/interval/new')}>
              새 프로그램
            </Button>
            <Button
              icon={CircleHelp}
              size="lg"
              style={styles.actionButton}
              variant="secondary"
              onPress={() => router.push('/interval/help')}>
              도움말
            </Button>
          </View>

          <View style={styles.section}>
            <Heading level={2}>저장된 프로그램</Heading>
            {programs.length === 0 ? (
              <EmptyProgramList />
            ) : (
              <ScrollView nestedScrollEnabled style={[styles.programList, { borderColor: theme.border }]}>
                <View style={styles.programListContent}>
                  {programs.map((program) => (
                    <Button
                      key={program.id}
                      icon={ListChecks}
                      variant="secondary"
                      onPress={() => router.push(`/interval/programs/${program.id}` as never)}>
                      {`${program.name} · ${formatDuration(program.workSeconds)} x ${program.rounds}`}
                    </Button>
                  ))}
                </View>
              </ScrollView>
            )}
          </View>
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
  actions: {
    flexDirection: 'row',
    gap: Spacing.two,
  },
  actionButton: {
    flex: 1,
  },
  section: {
    gap: Spacing.three,
  },
  programList: {
    borderTopWidth: 3,
    maxHeight: 420,
  },
  programListContent: {
    gap: Spacing.two,
    paddingTop: Spacing.two,
  },
  pressed: {
    opacity: 0.75,
    transform: [{ translateX: 1 }, { translateY: 1 }],
  },
});
