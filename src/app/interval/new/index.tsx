import { ArrowLeft, ArrowRight, Save } from 'lucide-react-native';
import { useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Button, Card, Heading, Input, NumberInput, Paragraph } from '@/components/ui';
import { DurationPicker, formatTimePart, type DurationParts } from '@/components/ui/time-picker';
import { Fonts, MaxContentWidth, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { createIntervalProgram, type CueMode } from '@/lib/interval-programs';

const steps = [
  {
    title: '1. 프로그램 이름',
    description: '예: Tabata 변형, 하체 EMOM, 파이트 곤 배드 스타일처럼 알아보기 쉬운 이름을 붙입니다.',
  },
  {
    title: '2. 준비 시간',
    description: '운동 시작 전에 준비할 시간을 정합니다. 바로 시작하려면 00:00:00으로 둡니다.',
  },
  {
    title: '3. 운동 시간',
    description: '각 라운드에서 실제로 운동하는 시간을 정합니다.',
  },
  {
    title: '4. 휴식 시간',
    description: '각 라운드 사이에 쉬는 시간을 정합니다. EMOM처럼 매 분 반복할 때는 00:00:00으로 둘 수 있습니다.',
  },
  {
    title: '5. 라운드',
    description: '구성한 운동/휴식 세트를 몇 번 반복할지 정합니다.',
  },
  {
    title: '6. 알림 큐',
    description: '기본값은 비프음입니다. 휴대폰이 진동 모드일 때는 진동으로 대체하는 흐름을 기본으로 둡니다.',
  },
];

function formatTime(value: DurationParts) {
  return `${formatTimePart(value.hours)}:${formatTimePart(value.minutes)}:${formatTimePart(value.seconds)}`;
}

function timeToSeconds(value: DurationParts) {
  return value.hours * 3600 + value.minutes * 60 + value.seconds;
}

function createInitialTime(minutes: number, seconds: number): DurationParts {
  return { hours: 0, minutes, seconds };
}

function secondsToTimeValue(totalSeconds: number): DurationParts {
  return {
    hours: 0,
    minutes: Math.floor(totalSeconds / 60),
    seconds: totalSeconds % 60,
  };
}

export default function NewIntervalProgramRoute() {
  const router = useRouter();
  const theme = useTheme();
  const [currentStep, setCurrentStep] = useState(0);
  const [name, setName] = useState('새 인터벌 프로그램');
  const [prepareTime, setPrepareTime] = useState(() => createInitialTime(0, 10));
  const [workTime, setWorkTime] = useState(() => createInitialTime(0, 20));
  const [restTime, setRestTime] = useState(() => createInitialTime(0, 10));
  const [rounds, setRounds] = useState('8');
  const [cueMode, setCueMode] = useState<CueMode>('beep');
  const [saving, setSaving] = useState(false);

  const isLastStep = currentStep === steps.length - 1;
  const canMoveNext = currentStep < steps.length - 1;
  const isValid = name.trim().length > 0 && Number(rounds) > 0;
  const canSave = isValid && !saving;
  const summary = useMemo(
    () => `${formatTime(prepareTime)} 준비 / ${formatTime(workTime)} 운동 / ${formatTime(restTime)} 휴식`,
    [prepareTime, restTime, workTime],
  );

  const handleSave = async () => {
    if (!canSave) {
      return;
    }

    try {
      setSaving(true);
      const program = await createIntervalProgram({
        cueMode,
        name: name.trim(),
        prepareSeconds: timeToSeconds(prepareTime),
        restSeconds: timeToSeconds(restTime),
        rounds: Number(rounds),
        workSeconds: timeToSeconds(workTime),
      });

      router.push(`/interval/programs/${program.id}` as never);
    } finally {
      setSaving(false);
    }
  };

  const renderStepInput = () => {
    switch (currentStep) {
      case 0:
        return <Input value={name} onChangeText={setName} />;
      case 1:
        return (
          <View style={styles.prepareOptions}>
            {[5, 10].map((option) => {
              const selected = timeToSeconds(prepareTime) === option;

              return (
                <Button
                  key={option}
                  size="lg"
                  style={styles.prepareOption}
                  variant={selected ? 'primary' : 'secondary'}
                  onPress={() => setPrepareTime(secondsToTimeValue(option))}>
                  {`${option}초`}
                </Button>
              );
            })}
          </View>
        );
      case 2:
        return <DurationPicker value={workTime} onChange={setWorkTime} />;
      case 3:
        return <DurationPicker value={restTime} onChange={setRestTime} />;
      case 4:
        return <NumberInput maxLength={2} value={rounds} onChangeText={setRounds} />;
      case 5:
      default:
        return (
          <>
            <Paragraph muted>{summary}</Paragraph>
            <Paragraph muted>기본값은 비프음입니다. 진동 모드에서는 진동으로 대체하는 것을 기준으로 합니다.</Paragraph>
            <View style={styles.cueOptions}>
              <Button
                size="sm"
                variant={cueMode === 'beep' ? 'primary' : 'secondary'}
                onPress={() => setCueMode('beep')}>
                비프음
              </Button>
              <Button
                size="sm"
                variant={cueMode === 'vibration' ? 'primary' : 'secondary'}
                onPress={() => setCueMode('vibration')}>
                진동
              </Button>
            </View>
          </>
        );
    }
  };

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

            <Button disabled={!canSave} icon={Save} size="sm" style={styles.saveButton} onPress={handleSave}>
              {saving ? '저장 중' : '저장'}
            </Button>
          </View>

          <Card>
            <Heading>새 프로그램</Heading>
            <Paragraph muted>인터벌 프로그램을 단계적으로 구성한 뒤 저장합니다.</Paragraph>
          </Card>

          <Card>
            <Text style={[styles.stepCounter, { color: theme.textSecondary }]}>
              {currentStep + 1} / {steps.length}
            </Text>
            <Heading level={2}>{steps[currentStep].title}</Heading>
            <Paragraph muted>{steps[currentStep].description}</Paragraph>
            <View style={styles.stepInput}>{renderStepInput()}</View>
          </Card>

          <View style={styles.navigation}>
            <Button
              disabled={currentStep === 0}
              icon={ArrowLeft}
              size="lg"
              style={styles.navButton}
              variant="secondary"
              onPress={() => setCurrentStep((step) => Math.max(0, step - 1))}>
              이전
            </Button>
            <Button
              disabled={isLastStep ? !canSave : !canMoveNext}
              icon={isLastStep ? Save : ArrowRight}
              size="lg"
              style={styles.navButton}
              onPress={isLastStep ? handleSave : () => setCurrentStep((step) => Math.min(steps.length - 1, step + 1))}>
              {isLastStep ? (saving ? '저장 중' : '저장') : '다음'}
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
  stepCounter: {
    fontFamily: Fonts.mono,
    fontSize: 14,
    fontWeight: '900',
    lineHeight: 18,
  },
  stepInput: {
    gap: Spacing.three,
    marginTop: Spacing.three,
  },
  cueOptions: {
    flexDirection: 'row',
    gap: Spacing.two,
  },
  prepareOptions: {
    flexDirection: 'row',
    gap: Spacing.two,
  },
  prepareOption: {
    flex: 1,
  },
  navigation: {
    flexDirection: 'row',
    gap: Spacing.two,
  },
  navButton: {
    flex: 1,
  },
  pressed: {
    opacity: 0.75,
    transform: [{ translateX: 1 }, { translateY: 1 }],
  },
});
