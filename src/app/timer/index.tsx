import * as Notifications from 'expo-notifications';
import { Picker } from '@react-native-picker/picker';
import { ArrowDown, ArrowUp, Pause, Play, RotateCcw } from 'lucide-react-native';
import { useEffect, useMemo, useRef, useState } from 'react';
import { Platform, Pressable, StyleSheet, Text, Vibration, View } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Button } from '@/components/ui';
import { Fonts, MaxContentWidth, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

type TimerMode = 'countdown' | 'countUp';
type TimerStatus = 'idle' | 'running' | 'paused' | 'completed';
const TIMER_NOTIFICATION_CHANNEL_ID = 'timer';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldPlaySound: true,
    shouldSetBadge: false,
    shouldShowBanner: true,
    shouldShowList: true,
  }),
});

type TimePickerColumnProps = {
  disabled: boolean;
  highlighted: boolean;
  label: string;
  max: number;
  onChange: (value: number) => void;
  value: number;
};

function formatNumber(value: number) {
  return String(value).padStart(2, '0');
}

function secondsToParts(totalSeconds: number) {
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;

  return { hours, minutes, seconds };
}

function TimePickerColumn({ disabled, highlighted, label, max, onChange, value }: TimePickerColumnProps) {
  const theme = useTheme();
  const items = useMemo(
    () =>
      Array.from({ length: max + 1 }, (_, itemValue) => {
        const formattedValue = formatNumber(itemValue);
        return { label: formattedValue, value: String(itemValue) };
      }),
    [max],
  );

  return (
    <View
      accessibilityLabel={label}
      style={[
        styles.pickerColumn,
        {
          backgroundColor: highlighted ? theme.primary : theme.surfaceStrong,
          borderColor: theme.border,
          opacity: disabled ? 0.95 : 1,
        },
      ]}>
      {disabled ? (
        <View style={styles.lockedPickerValue}>
          <Text style={[styles.lockedPickerText, { color: highlighted ? '#111111' : theme.text }]}>
            {formatNumber(value)}
          </Text>
        </View>
      ) : (
        <Picker
          enabled
          dropdownIconColor={theme.text}
          itemStyle={[styles.nativePickerItem, { color: theme.text }]}
          mode="dropdown"
          prompt={`${label} 선택`}
          selectedValue={String(value)}
          style={[styles.nativePicker, { color: theme.text }]}
          onValueChange={(itemValue) => onChange(Number(itemValue))}>
          {items.map((item) => (
            <Picker.Item color={theme.text} key={item.value} label={item.label} value={item.value} />
          ))}
        </Picker>
      )}
      <Text style={[styles.columnLabel, { color: highlighted ? '#111111' : theme.textSecondary }]}>{label}</Text>
    </View>
  );
}

export default function TimerRoute() {
  const router = useRouter();
  const theme = useTheme();
  const [mode, setMode] = useState<TimerMode>('countdown');
  const [hours, setHours] = useState(0);
  const [minutes, setMinutes] = useState(5);
  const [seconds, setSeconds] = useState(0);
  const [remainingSeconds, setRemainingSeconds] = useState(300);
  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  const [status, setStatus] = useState<TimerStatus>('idle');
  const notificationIdRef = useRef<string | null>(null);

  const configuredSeconds = useMemo(
    () => hours * 3600 + minutes * 60 + seconds,
    [hours, minutes, seconds],
  );

  const shownParts = useMemo(() => {
    if (status === 'idle' || status === 'completed') {
      return { hours, minutes, seconds };
    }

    return mode === 'countdown' ? secondsToParts(remainingSeconds) : secondsToParts(elapsedSeconds);
  }, [elapsedSeconds, hours, minutes, mode, remainingSeconds, seconds, status]);

  const pickerDisabled = status === 'running' || status === 'paused';
  const timerHighlighted = status === 'running';
  const canStart = status === 'paused'
    ? mode === 'countdown'
      ? remainingSeconds > 0
      : elapsedSeconds < configuredSeconds
    : configuredSeconds > 0;
  const targetTimeText = `${formatNumber(hours)}:${formatNumber(minutes)}:${formatNumber(seconds)}`;

  useEffect(() => {
    if (status !== 'running') {
      return;
    }

    const intervalId = setInterval(() => {
      if (mode === 'countdown') {
        setRemainingSeconds((current) => {
          if (current <= 1) {
            setStatus('completed');
            Vibration.vibrate(500);
            return 0;
          }

          return current - 1;
        });
        return;
      }

      setElapsedSeconds((current) => {
        if (current + 1 >= configuredSeconds) {
          setStatus('completed');
          Vibration.vibrate(500);
          return configuredSeconds;
        }

        return current + 1;
      });
    }, 1000);

    return () => clearInterval(intervalId);
  }, [configuredSeconds, mode, status]);

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
      await Notifications.setNotificationChannelAsync(TIMER_NOTIFICATION_CHANNEL_ID, {
        enableVibrate: true,
        importance: Notifications.AndroidImportance.HIGH,
        name: 'Timer',
        vibrationPattern: [0, 500],
      });
    }

    notificationIdRef.current = await Notifications.scheduleNotificationAsync({
      content: {
        title: 'Tempo',
        body: '타이머가 완료되었습니다.',
      },
      trigger: {
        channelId: TIMER_NOTIFICATION_CHANNEL_ID,
        type: Notifications.SchedulableTriggerInputTypes.TIME_INTERVAL,
        seconds: Math.max(1, durationSeconds),
      },
    });
  };

  const handleAction = () => {
    if (status === 'running') {
      void cancelCompletionNotification();
      setStatus('paused');
      return;
    }

    if (!canStart) {
      return;
    }

    if (status === 'idle' || status === 'completed') {
      setRemainingSeconds(configuredSeconds);
      setElapsedSeconds(0);
      void scheduleCompletionNotification(configuredSeconds);
    } else {
      const durationSeconds = mode === 'countdown' ? remainingSeconds : configuredSeconds - elapsedSeconds;
      void scheduleCompletionNotification(durationSeconds);
    }

    setStatus('running');
  };

  const handleReset = () => {
    void cancelCompletionNotification();
    setRemainingSeconds(configuredSeconds);
    setElapsedSeconds(0);
    setStatus('idle');
  };

  const handleModeChange = (nextMode: TimerMode) => {
    if (nextMode === mode) {
      return;
    }

    if (status === 'running' || status === 'paused') {
      if (mode === 'countdown') {
        setElapsedSeconds(configuredSeconds - remainingSeconds);
      } else {
        setRemainingSeconds(configuredSeconds - elapsedSeconds);
      }
    }

    setMode(nextMode);
    if (status === 'idle' || status === 'completed') {
      setRemainingSeconds(configuredSeconds);
      setElapsedSeconds(0);
    }
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
              onPress={() => (router.canGoBack() ? router.back() : router.replace('/'))}
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
                variant={mode === 'countdown' ? 'primary' : 'secondary'}
                style={styles.modeButton}
                onPress={() => handleModeChange('countdown')}>
                다운
              </Button>
              <Button
                icon={ArrowUp}
                size="sm"
                variant={mode === 'countUp' ? 'primary' : 'secondary'}
                style={styles.modeButton}
                onPress={() => handleModeChange('countUp')}>
                업
              </Button>
            </View>
          </View>

          <View style={styles.timerPanel}>
            <Text style={[styles.targetTime, { color: theme.textSecondary }]}>{targetTimeText}</Text>

            <View style={styles.picker}>
              <TimePickerColumn
                disabled={pickerDisabled}
                highlighted={timerHighlighted}
                label="시간"
                max={99}
                value={shownParts.hours}
                onChange={setHours}
              />
              <TimePickerColumn
                disabled={pickerDisabled}
                highlighted={timerHighlighted}
                label="분"
                max={59}
                value={shownParts.minutes}
                onChange={setMinutes}
              />
              <TimePickerColumn
                disabled={pickerDisabled}
                highlighted={timerHighlighted}
                label="초"
                max={59}
                value={shownParts.seconds}
                onChange={setSeconds}
              />
            </View>
          </View>

          <View style={styles.actions}>
            <Button
              disabled={!canStart}
              icon={buttonIcon}
              size="lg"
              style={styles.actionButton}
              onPress={handleAction}>
              {buttonLabel}
            </Button>

            {status === 'paused' ? (
              <Button
                icon={RotateCcw}
                size="lg"
                style={styles.actionButton}
                variant="secondary"
                onPress={handleReset}>
                리셋
              </Button>
            ) : null}
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
    flex: 1,
    alignItems: 'center',
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
    fontWeight: 900,
    lineHeight: 20,
  },
  modeToggle: {
    flexDirection: 'row',
    gap: Spacing.two,
  },
  modeButton: {
    minWidth: 88,
  },
  timerPanel: {
    gap: Spacing.two,
    width: '100%',
  },
  targetTime: {
    fontFamily: Fonts.sans,
    fontSize: 32,
    fontWeight: '900',
    lineHeight: 38,
    textAlign: 'center',
  },
  picker: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: Spacing.two,
    width: '100%',
  },
  pickerColumn: {
    alignItems: 'center',
    borderRadius: 8,
    borderWidth: 3,
    flex: 1,
    gap: Spacing.two,
    justifyContent: 'center',
    minHeight: 132,
    paddingHorizontal: Spacing.two,
    paddingVertical: Spacing.three,
  },
  nativePicker: {
    alignSelf: 'stretch',
    minHeight: 92,
  },
  lockedPickerValue: {
    alignItems: 'center',
    alignSelf: 'stretch',
    justifyContent: 'center',
    minHeight: 92,
  },
  lockedPickerText: {
    fontFamily: Fonts.mono,
    fontSize: 56,
    fontWeight: '900',
    letterSpacing: 0,
    lineHeight: 64,
  },
  nativePickerItem: {
    fontFamily: Fonts.mono,
    fontSize: 16,
    fontWeight: '900',
    letterSpacing: 0,
    lineHeight: 64,
  },
  columnLabel: {
    fontFamily: Fonts.sans,
    fontSize: 12,
    fontWeight: 900,
    lineHeight: 16,
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
