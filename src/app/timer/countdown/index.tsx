import { Pause, Play, RotateCcw } from 'lucide-react-native';
import { useEffect, useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';

import { Button, Card, Heading, NumberInput, Paragraph, UiText } from '@/components/ui';
import { Fonts, MaxContentWidth, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

type CountdownStatus = 'idle' | 'running' | 'paused' | 'completed';

function clampTimeInput(value: string, max: number) {
  const digits = value.replace(/\D/g, '').slice(0, 2);
  if (digits.length === 0) {
    return '';
  }

  return String(Math.min(Number(digits), max));
}

function formatTime(totalSeconds: number) {
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;

  return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
}

export default function CountdownRoute() {
  const router = useRouter();
  const theme = useTheme();
  const [minutes, setMinutes] = useState('5');
  const [seconds, setSeconds] = useState('0');
  const [remainingSeconds, setRemainingSeconds] = useState(300);
  const [status, setStatus] = useState<CountdownStatus>('idle');

  const configuredSeconds = useMemo(() => {
    return Number(minutes || 0) * 60 + Number(seconds || 0);
  }, [minutes, seconds]);

  const displaySeconds = status === 'idle' ? configuredSeconds : remainingSeconds;
  const isEditable = status === 'idle';
  const canStart = configuredSeconds > 0 || remainingSeconds > 0;

  useEffect(() => {
    if (status !== 'running') {
      return;
    }

    const intervalId = setInterval(() => {
      setRemainingSeconds((current) => {
        if (current <= 1) {
          setStatus('completed');
          return 0;
        }

        return current - 1;
      });
    }, 1000);

    return () => clearInterval(intervalId);
  }, [status]);

  const handleStart = () => {
    if (!canStart) {
      return;
    }

    if (status === 'idle' || status === 'completed') {
      setRemainingSeconds(configuredSeconds);
    }

    setStatus('running');
  };

  const handlePause = () => {
    setStatus('paused');
  };

  const handleReset = () => {
    setRemainingSeconds(configuredSeconds);
    setStatus('idle');
  };

  return (
    <ScrollView style={[styles.screen, { backgroundColor: theme.background }]}>
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

          <Card tone={status === 'completed' ? 'work' : 'primary'} style={styles.timerCard}>
            <Heading level={2} style={styles.timerHeading}>카운트다운</Heading>
            <Text style={[styles.timerText, { color: '#111111' }]}>{formatTime(displaySeconds)}</Text>
            <Paragraph style={styles.statusText}>
              {status === 'running'
                ? '실행 중'
                : status === 'paused'
                  ? '일시정지'
                  : status === 'completed'
                    ? '완료'
                    : '대기'}
            </Paragraph>
          </Card>

          <Card>
            <Heading level={3}>시간 설정</Heading>
            <Paragraph muted>분과 초를 맞춘 뒤 바로 시작합니다.</Paragraph>

            <View style={styles.inputRow}>
              <View style={styles.inputGroup}>
                <NumberInput
                  accessibilityLabel="분"
                  editable={isEditable}
                  maxLength={2}
                  onChangeText={(value) => setMinutes(clampTimeInput(value, 99))}
                  value={minutes}
                />
                <UiText variant="caption">분</UiText>
              </View>

              <Text style={[styles.separator, { color: theme.text }]}>:</Text>

              <View style={styles.inputGroup}>
                <NumberInput
                  accessibilityLabel="초"
                  editable={isEditable}
                  maxLength={2}
                  onChangeText={(value) => setSeconds(clampTimeInput(value, 59))}
                  value={seconds}
                />
                <UiText variant="caption">초</UiText>
              </View>
            </View>
          </Card>

          <View style={styles.actions}>
            {status === 'running' ? (
              <Button icon={Pause} size="lg" variant="secondary" onPress={handlePause}>
                일시정지
              </Button>
            ) : (
              <Button disabled={!canStart} icon={Play} size="lg" onPress={handleStart}>
                {status === 'paused' ? '재개' : '시작'}
              </Button>
            )}

            <Button icon={RotateCcw} size="lg" variant="secondary" onPress={handleReset}>
              리셋
            </Button>
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
    flex: 1,
    alignItems: 'center',
    paddingBottom: Spacing.three,
    paddingHorizontal: Spacing.four,
    paddingTop: Spacing.four,
  },
  container: {
    flex: 1,
    gap: Spacing.four,
    width: '100%',
    maxWidth: MaxContentWidth,
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
  timerCard: {
    gap: Spacing.three,
  },
  timerHeading: {
    color: '#111111',
  },
  timerText: {
    fontFamily: Fonts.mono,
    fontSize: 72,
    fontWeight: 900,
    letterSpacing: 0,
    lineHeight: 82,
    textAlign: 'center',
  },
  statusText: {
    color: '#111111',
    textAlign: 'center',
  },
  inputRow: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: Spacing.two,
    marginTop: Spacing.three,
  },
  inputGroup: {
    flex: 1,
    gap: Spacing.two,
  },
  separator: {
    fontFamily: Fonts.mono,
    fontSize: 32,
    fontWeight: 900,
    lineHeight: 40,
    paddingBottom: 24,
  },
  actions: {
    gap: Spacing.three,
  },
  pressed: {
    opacity: 0.75,
    transform: [{ translateX: 1 }, { translateY: 1 }],
  },
});
