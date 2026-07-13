import { Pause, Play, RotateCcw, TimerReset } from 'lucide-react-native';
import { useEffect, useMemo, useRef, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Button } from '@/components/ui';
import { Fonts, MaxContentWidth, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

type StopwatchStatus = 'idle' | 'running' | 'paused';

function formatNumber(value: number) {
  return String(value).padStart(2, '0');
}

function formatStopwatchTime(elapsedMs: number) {
  const totalCentiseconds = Math.floor(elapsedMs / 10);
  const centiseconds = totalCentiseconds % 100;
  const totalSeconds = Math.floor(totalCentiseconds / 100);
  const seconds = totalSeconds % 60;
  const totalMinutes = Math.floor(totalSeconds / 60);
  const minutes = totalMinutes % 60;
  const hours = Math.floor(totalMinutes / 60);

  return `${formatNumber(hours)}:${formatNumber(minutes)}:${formatNumber(seconds)}.${formatNumber(centiseconds)}`;
}

export default function StopwatchRoute() {
  const router = useRouter();
  const theme = useTheme();
  const [elapsedMs, setElapsedMs] = useState(0);
  const [laps, setLaps] = useState<number[]>([]);
  const [status, setStatus] = useState<StopwatchStatus>('idle');
  const startedAtRef = useRef<number | null>(null);

  const isRunning = status === 'running';
  const displayTime = useMemo(() => formatStopwatchTime(elapsedMs), [elapsedMs]);

  useEffect(() => {
    if (!isRunning) {
      return;
    }

    const intervalId = setInterval(() => {
      if (startedAtRef.current) {
        setElapsedMs(Date.now() - startedAtRef.current);
      }
    }, 50);

    return () => clearInterval(intervalId);
  }, [isRunning]);

  const handleStartStop = () => {
    if (isRunning) {
      setStatus('paused');
      return;
    }

    startedAtRef.current = Date.now() - elapsedMs;
    setStatus('running');
  };

  const handleLapReset = () => {
    if (isRunning) {
      setLaps((current) => [elapsedMs, ...current]);
      return;
    }

    setElapsedMs(0);
    setLaps([]);
    startedAtRef.current = null;
    setStatus('idle');
  };

  const startStopLabel = isRunning ? '중지' : '시작';
  const startStopIcon = isRunning ? Pause : Play;
  const lapResetLabel = isRunning ? '랩' : '리셋';
  const lapResetIcon = isRunning ? TimerReset : RotateCcw;

  return (
    <View style={[styles.screen, { backgroundColor: theme.background }]}>
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.container}>
          <Pressable
            accessibilityRole="button"
            onPress={() => (router.canGoBack() ? router.back() : router.replace('/'))}
            style={({ pressed }) => [
              styles.backButton,
              { backgroundColor: theme.surface, borderColor: theme.border },
              pressed && styles.pressed,
            ]}>
            <Text style={[styles.backButtonText, { color: theme.text }]}>← 뒤로</Text>
          </Pressable>

          <View
            style={[
              styles.timePanel,
              {
                backgroundColor: isRunning ? theme.primary : theme.surfaceStrong,
                borderColor: theme.border,
              },
            ]}>
            <Text
              adjustsFontSizeToFit
              minimumFontScale={0.72}
              numberOfLines={1}
              style={[styles.timeText, { color: isRunning ? '#111111' : theme.text }]}>
              {displayTime}
            </Text>
          </View>

          <View style={styles.lapPanel}>
            <Text style={[styles.lapTitle, { color: theme.textSecondary }]}>랩</Text>
            <ScrollView
              contentContainerStyle={styles.lapList}
              showsVerticalScrollIndicator={false}
              style={[styles.lapScroll, { borderColor: theme.border }]}>
              {laps.length === 0 ? (
                <Text style={[styles.emptyLapText, { color: theme.textSecondary }]}>기록 없음</Text>
              ) : (
                laps.map((lap, index) => (
                  <View
                    key={`${lap}-${laps.length - index}`}
                    style={[
                      styles.lapRow,
                      { backgroundColor: theme.surfaceStrong, borderColor: theme.border },
                    ]}>
                    <Text style={[styles.lapIndex, { color: theme.textSecondary }]}>
                      {formatNumber(laps.length - index)}
                    </Text>
                    <Text
                      adjustsFontSizeToFit
                      minimumFontScale={0.8}
                      numberOfLines={1}
                      style={[styles.lapTime, { color: theme.text }]}>
                      {formatStopwatchTime(lap)}
                    </Text>
                  </View>
                ))
              )}
            </ScrollView>
          </View>

          <View style={styles.actions}>
            <Button icon={startStopIcon} size="lg" style={styles.actionButton} onPress={handleStartStop}>
              {startStopLabel}
            </Button>
            <Button
              disabled={!isRunning && elapsedMs === 0 && laps.length === 0}
              icon={lapResetIcon}
              size="lg"
              style={styles.actionButton}
              variant="secondary"
              onPress={handleLapReset}>
              {lapResetLabel}
            </Button>
          </View>
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
  timePanel: {
    alignItems: 'center',
    borderRadius: 8,
    borderWidth: 3,
    justifyContent: 'center',
    minHeight: 156,
    paddingHorizontal: Spacing.three,
    paddingVertical: Spacing.four,
  },
  timeText: {
    fontFamily: Fonts.mono,
    fontSize: 48,
    fontWeight: '900',
    letterSpacing: 0,
    lineHeight: 56,
  },
  lapPanel: {
    flex: 1,
    gap: Spacing.two,
    minHeight: 120,
  },
  lapTitle: {
    fontFamily: Fonts.sans,
    fontSize: 16,
    fontWeight: '900',
    lineHeight: 20,
    textAlign: 'center',
  },
  lapScroll: {
    borderTopWidth: 3,
  },
  lapList: {
    gap: Spacing.two,
    paddingTop: Spacing.two,
  },
  emptyLapText: {
    fontFamily: Fonts.sans,
    fontSize: 16,
    fontWeight: '900',
    lineHeight: 22,
    paddingVertical: Spacing.four,
    textAlign: 'center',
  },
  lapRow: {
    alignItems: 'center',
    borderRadius: 8,
    borderWidth: 3,
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.three,
    paddingVertical: Spacing.two,
  },
  lapIndex: {
    fontFamily: Fonts.sans,
    fontSize: 14,
    fontWeight: '900',
    lineHeight: 18,
  },
  lapTime: {
    fontFamily: Fonts.mono,
    fontSize: 20,
    fontWeight: '900',
    letterSpacing: 0,
    lineHeight: 26,
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
