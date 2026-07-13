import { CirclePlay, ListChecks, Pencil, Trash2 } from 'lucide-react-native';
import { useEffect, useState } from 'react';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Alert, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Button, Card, Heading, Paragraph, Table, TableCell, TableRow } from '@/components/ui';
import { MaxContentWidth, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { deleteIntervalProgram, formatDuration, getIntervalProgram, type IntervalProgram } from '@/lib/interval-programs';

function cueLabel(value: string) {
  return value === 'vibration' ? '진동' : '비프음';
}

export default function CustomPresetDetailRoute() {
  const router = useRouter();
  const theme = useTheme();
  const { id } = useLocalSearchParams<{ id: string }>();
  const [program, setProgram] = useState<IntervalProgram | null>(null);
  const programId = Number(Array.isArray(id) ? id[0] : id);

  useEffect(() => {
    if (!Number.isFinite(programId)) {
      return;
    }

    let mounted = true;

    void getIntervalProgram(programId).then((nextProgram) => {
      if (mounted) {
        setProgram(nextProgram);
      }
    });

    return () => {
      mounted = false;
    };
  }, [programId]);

  const handleDelete = () => {
    Alert.alert('프로그램 삭제', '삭제하시겠습니까?', [
      { style: 'cancel', text: '취소' },
      {
        style: 'destructive',
        text: '삭제',
        onPress: () => {
          void deleteIntervalProgram(programId).then(() => router.replace('/interval/programs'));
        },
      },
    ]);
  };

  return (
    <ScrollView style={[styles.screen, { backgroundColor: theme.background }]}>
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.container}>
          <Pressable
            accessibilityRole="button"
            onPress={() => router.replace('/interval/programs')}
            style={({ pressed }) => [
              styles.backButton,
              { backgroundColor: theme.surface, borderColor: theme.border },
              pressed && styles.pressed,
            ]}>
            <Text style={[styles.backButtonText, { color: theme.text }]}>← 목록으로가기</Text>
          </Pressable>

          {program ? (
            <>
              <Card>
                <Heading>{program.name}</Heading>
                <Paragraph muted>저장된 인터벌 프로그램 입력사항입니다.</Paragraph>
              </Card>

              <Table>
                <TableRow header>
                  <TableCell header>항목</TableCell>
                  <TableCell header>값</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell>준비</TableCell>
                  <TableCell>{formatDuration(program.prepareSeconds)}</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell>운동</TableCell>
                  <TableCell>{formatDuration(program.workSeconds)}</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell>휴식</TableCell>
                  <TableCell>{formatDuration(program.restSeconds)}</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell>라운드</TableCell>
                  <TableCell>{String(program.rounds)}</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell>알림 큐</TableCell>
                  <TableCell>{cueLabel(program.cueMode)}</TableCell>
                </TableRow>
              </Table>

              <View style={styles.actions}>
                <Button
                  icon={CirclePlay}
                  size="lg"
                  style={styles.actionButton}
                  onPress={() => router.push(`/interval/run?programId=${program.id}` as never)}>
                  실행
                </Button>
                <Button
                  icon={ListChecks}
                  size="lg"
                  style={styles.actionButton}
                  variant="secondary"
                  onPress={() => router.replace('/interval/programs')}>
                  목록으로가기
                </Button>
              </View>

              <View style={styles.actions}>
                <Button
                  icon={Pencil}
                  size="lg"
                  style={styles.actionButton}
                  variant="secondary"
                  onPress={() => router.push(`/interval/programs/${program.id}/edit` as never)}>
                  수정
                </Button>
                <Button icon={Trash2} size="lg" style={styles.actionButton} variant="danger" onPress={handleDelete}>
                  삭제
                </Button>
              </View>
            </>
          ) : (
            <Card>
              <Heading>프로그램을 찾을 수 없습니다</Heading>
              <Paragraph muted>목록으로 돌아가 저장된 프로그램을 다시 선택하세요.</Paragraph>
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
  actions: {
    flexDirection: 'row',
    gap: Spacing.two,
  },
  actionButton: {
    flex: 1,
  },
  pressed: {
    opacity: 0.75,
    transform: [{ translateX: 1 }, { translateY: 1 }],
  },
});
