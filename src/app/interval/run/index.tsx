import { Audio } from 'expo-av';
import * as Notifications from 'expo-notifications';
import { ArrowDown, ArrowUp, Pause, Play, RotateCcw } from 'lucide-react-native';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Platform, Pressable, StyleSheet, Text, Vibration, View } from 'react-native';
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

const phaseThemeColor: Record<IntervalPhase, 'prepare' | 'rest' | 'work'> = {
  prepare: 'prepare',
  rest: 'rest',
  work: 'work',
};

const beepSound = require('../../../../assets/sounds/beep.wav');
const INTERVAL_NOTIFICATION_CHANNEL_ID = 'interval';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldPlaySound: true,
    shouldSetBadge: false,
    shouldShowBanner: true,
    shouldShowList: true,
  }),
});

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
  const cueKeyRef = useRef<string | null>(null);
  const notificationIdRef = useRef<string | null>(null);

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
    void Audio.setAudioModeAsync({
      playsInSilentModeIOS: true,
    });
  }, []);

  useEffect(() => {
    return () => {
      void cancelCompletionNotification();
    };
  }, []);

  const cancelCompletionNotification = async () => {
    if (!notificationIdRef.current) {
      return;
    }

    await Notifications.cancelScheduledNotificationAsync(notificationIdRef.current);
    notificationIdRef.current = null;
  };

  const scheduleCompletionNotification = async (durationSeconds: number) => {
    await cancelCompletionNotification();

    const permissions = await Notifications.requestPermissionsAsync();
    if (!permissions.granted) {
      return;
    }

    if (Platform.OS === 'android') {
      await Notifications.setNotificationChannelAsync(INTERVAL_NOTIFICATION_CHANNEL_ID, {
        enableVibrate: true,
        importance: Notifications.AndroidImportance.HIGH,
        name: 'Interval',
        vibrationPattern: [0, 500],
      });
    }

    notificationIdRef.current = await Notifications.scheduleNotificationAsync({
      content: {
        title: 'Tempo',
        body: program ? `${program.name} 프로그램이 완료되었습니다.` : '인터벌 프로그램이 완료되었습니다.',
      },
      trigger: {
        channelId: INTERVAL_NOTIFICATION_CHANNEL_ID,
        type: Notifications.SchedulableTriggerInputTypes.TIME_INTERVAL,
        seconds: Math.max(1, durationSeconds),
      },
    });
  };

  const getRemainingRunSeconds = () => {
    if (!currentSegment) {
      return 0;
    }

    const currentRemainingSeconds = Math.max(0, currentSegment.durationSeconds - elapsedInSegment);
    const nextSegmentsSeconds = segments
      .slice(segmentIndex + 1)
      .reduce((totalSeconds, segment) => totalSeconds + segment.durationSeconds, 0);

    return currentRemainingSeconds + nextSegmentsSeconds;
  };

  const playCue = useCallback(async () => {
    if (program?.cueMode === 'vibration') {
      Vibration.vibrate(180);
      return;
    }

    const { sound } = await Audio.Sound.createAsync(beepSound, { shouldPlay: true });
    sound.setOnPlaybackStatusUpdate((playbackStatus) => {
      if (playbackStatus.isLoaded && playbackStatus.didJustFinish) {
        void sound.unloadAsync();
      }
    });
  }, [program?.cueMode]);

  useEffect(() => {
    if (
      status !== 'running' ||
      !currentSegment ||
      currentSegment.durationSeconds <= 3 ||
      currentSegment.phase === 'prepare'
    ) {
      return;
    }

    const remainingSeconds = currentSegment.durationSeconds - elapsedInSegment;

    if (remainingSeconds < 1 || remainingSeconds > 3) {
      return;
    }

    const cueKey = `${segmentIndex}:${remainingSeconds}`;

    if (cueKeyRef.current === cueKey) {
      return;
    }

    cueKeyRef.current = cueKey;
    void playCue();
  }, [currentSegment, elapsedInSegment, playCue, segmentIndex, status]);

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
      void cancelCompletionNotification();
      setStatus('paused');
      return;
    }

    if (!canStart) {
      return;
    }

    void scheduleCompletionNotification(getRemainingRunSeconds());
    setStatus('running');
  };

  const handleReset = () => {
    void cancelCompletionNotification();
    setStatus('idle');
    setSegmentIndex(0);
    setElapsedInSegment(0);
    cueKeyRef.current = null;
  };

  const buttonLabel = status === 'running' ? '일시정지' : status === 'paused' ? '재개' : '시작';
  const buttonIcon = status === 'running' ? Pause : Play;
  const activeBackgroundColor = currentSegment ? theme[phaseThemeColor[currentSegment.phase]] : theme.primary;

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
                    backgroundColor: status === 'running' ? activeBackgroundColor : theme.surfaceStrong,
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
