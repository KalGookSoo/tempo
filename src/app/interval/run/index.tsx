import { ArrowDown, ArrowUp, Pause, Play, RotateCcw } from 'lucide-react-native';
import { useEffect, useMemo, useState } from 'react';
import { Pressable, StyleSheet, Text, Vibration, View } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Button, Card, Heading, Paragraph } from '@/components/ui';
import { Fonts, MaxContentWidth, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { formatDuration, getIntervalProgram, type IntervalProgram } from '@/lib/interval-programs';

type RunMode = 'countdown' | 'countUp';
type RunStatus = 'idle' | 'running' | 'paused' | 'completed';
type IntervalPhase = 'prepare' | 'work' | 'rest';

type IntervalSegment = {
  durationSeconds: number;
  phase: IntervalPhase;
  round: number;
};

const phaseLabel: Record<IntervalPhase, string> = {
  prepare: '준비',
  rest: '휴식',
  work: '운동',
};

function buildSegments(program: IntervalProgram) {
  const segments: IntervalSegment[] = [];

  if (program.prepareSeconds > 0) {
    segments.push({ durationSeconds: program.prepareSeconds, phase: 'prepare', round: 0 });
  }

  for (let round = 1; round <= program.rounds; round += 1) {
    if (program.workSeconds > 0) {
      segments.push({ durationSeconds: program.workSeconds, phase: 'work', round });
    }

    if (round < program.rounds && program.restSeconds > 0) {
      segments.push({ durationSeconds: program.restSeconds, phase: 'rest', round });
    }
  }

  return segments;
}

export default function IntervalRunRoute() {
  const router = useRouter();
  const theme = useTheme();
  const { programId } = useLocalSearchParams<{ programId?: string }>();
  const numericProgramId = Number(Array.isArray(programId) ? programId[0] : programId);
  const [program, setProgram] = useState<IntervalProgram | null>(null);
  const [mode, setMode] = useState<RunMode>('countdown');
  const [status, setStatus] = useState<RunStatus>('idle');
  const [segmentIndex, setSegmentIndex] = useState(0);
  const [elapsedInSegment, setElapsedInSegment] = useState(0);

  useEffect(() => {
    if (!Number.isFinite(numericProgramId)) {
      return;
    }

    let mounted = true;

    void getIntervalProgram(numericProgramId).then((nextProgram) => {
      if (mounted) {
        setProgram(nextProgram);
      }
    });

    return () => {
      mounted = false;
    };
  }, [numericProgramId]);

  const segments = useMemo(() => (program ? buildSegments(program) : []), [program]);
  const currentSegment = segments[segmentIndex] ?? null;
  const shownSeconds = currentSegment
    ? mode === 'countdown'
      ? Math.max(0, currentSegment.durationSeconds - elapsedInSegment)
      : elapsedInSegment
    : 0;
  const canStart = segments.length > 0 && status !== 'completed';
  const roundLabel = currentSegment?.round ? `${currentSegment.round} / ${program?.rounds ?? 0}` : '-';

  useEffect(() => {
    if (status !== 'running' || !currentSegment) {
      return;
    }

    const intervalId = setInterval(() => {
      setElapsedInSegment((currentElapsed) => {
        const nextElapsed = currentElapsed + 1;

        if (nextElapsed < currentSegment.durationSeconds) {
          return nextElapsed;
        }

        setSegmentIndex((currentIndex) => {
          const nextIndex = currentIndex + 1;

          if (nextIndex >= segments.length) {
            setStatus('completed');
            Vibration.vibrate(500);
            return currentIndex;
          }

          return nextIndex;
        });

        return 0;
      });
    }, 1000);

    return () => clearInterval(intervalId);
  }, [currentSegment, segments.length, status]);

  const handleAction = () => {
    if (status === 'running') {
      setStatus('paused');
      return;
    }

    if (!canStart) {
      return;
    }

    setStatus('running');
  };

  const handleReset = () => {
    setStatus('idle');
    setSegmentIndex(0);
    setElapsedInSegment(0);
  };

  const buttonLabel = status === 'running' ? '일시정지' : status === 'paused' ? '재개' : '시작';
  const buttonIcon = status === 'running' ? Pause : Play;

  return (
    <View style={[styles.screen, { backgroundColor: theme.background }]}>
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.container}>
          <View style={styles.header}>
            <Pressable
              accessibilityRole="button"
              onPress={() => (router.canGoBack() ? router.back() : router.replace('/interval/programs'))}
              style={({ pressed }) => [
                styles.backButton,
                { backgroundColor: theme.surface, borderColor: theme.border },
                pressed && styles.pressed,
              ]}>
              <Text style={[styles.backButtonText, { color: theme.text }]}>← 뒤로</Text>
            </Pressable>

            <View style={styles.modeToggle}>
              <Button
                icon={ArrowDown}
                size="sm"
                style={styles.modeButton}
                variant={mode === 'countdown' ? 'primary' : 'secondary'}
                onPress={() => setMode('countdown')}>
                다운
              </Button>
              <Button
                icon={ArrowUp}
                size="sm"
                style={styles.modeButton}
                variant={mode === 'countUp' ? 'primary' : 'secondary'}
                onPress={() => setMode('countUp')}>
                업
              </Button>
            </View>
          </View>

          {program && currentSegment ? (
            <>
              <View style={styles.phaseHeader}>
                <Text style={[styles.phaseText, { color: theme.text }]}>
                  {status === 'completed' ? '완료' : phaseLabel[currentSegment.phase]}
                </Text>
                <Text style={[styles.roundText, { color: theme.textSecondary }]}>라운드 {roundLabel}</Text>
              </View>

              <View
                style={[
                  styles.timePanel,
                  {
                    backgroundColor: status === 'running' ? theme.primary : theme.surfaceStrong,
                    borderColor: theme.border,
                  },
                ]}>
                <Text style={[styles.timeText, { color: status === 'running' ? '#111111' : theme.text }]}>
                  {status === 'completed' ? '00:00:00' : formatDuration(shownSeconds)}
                </Text>
              </View>

              <Text style={[styles.programName, { color: theme.textSecondary }]}>{program.name}</Text>

              <View style={styles.actions}>
                <Button disabled={!canStart} icon={buttonIcon} size="lg" style={styles.actionButton} onPress={handleAction}>
                  {buttonLabel}
                </Button>
                <Button icon={RotateCcw} size="lg" style={styles.actionButton} variant="secondary" onPress={handleReset}>
                  리셋
                </Button>
              </View>
            </>
          ) : (
            <Card>
              <Heading>실행할 프로그램이 없습니다</Heading>
              <Paragraph muted>프로그램 목록에서 실행할 프로그램을 선택하세요.</Paragraph>
            </Card>
          )}
        </View>
      </SafeAreaView>
    </View>
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
    flex: 1,
    gap: Spacing.five,
    justifyContent: 'space-between',
    maxWidth: MaxContentWidth,
    width: '100%',
  },
  header: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: Spacing.three,
    justifyContent: 'space-between',
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
  modeToggle: {
    flexDirection: 'row',
    gap: Spacing.two,
  },
  modeButton: {
    minWidth: 88,
  },
  phaseHeader: {
    alignItems: 'center',
    gap: Spacing.one,
  },
  phaseText: {
    fontFamily: Fonts.sans,
    fontSize: 40,
    fontWeight: '900',
    lineHeight: 48,
  },
  roundText: {
    fontFamily: Fonts.sans,
    fontSize: 16,
    fontWeight: '900',
    lineHeight: 20,
  },
  timePanel: {
    alignItems: 'center',
    borderRadius: 8,
    borderWidth: 3,
    justifyContent: 'center',
    minHeight: 168,
    paddingHorizontal: Spacing.three,
    paddingVertical: Spacing.four,
  },
  timeText: {
    fontFamily: Fonts.mono,
    fontSize: 56,
    fontWeight: '900',
    letterSpacing: 0,
    lineHeight: 64,
  },
  programName: {
    fontFamily: Fonts.sans,
    fontSize: 20,
    fontWeight: '900',
    lineHeight: 28,
    textAlign: 'center',
  },
  actions: {
    flexDirection: 'row',
    gap: Spacing.two,
    width: '100%',
  },
  actionButton: {
    flex: 1,
  },
  pressed: {
    opacity: 0.75,
    transform: [{ translateX: 1 }, { translateY: 1 }],
  },
});
