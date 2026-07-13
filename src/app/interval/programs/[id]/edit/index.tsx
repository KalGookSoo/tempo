import { ArrowLeft, ArrowRight, Save } from 'lucide-react-native';
import { useEffect, useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Button, Card, Heading, Input, NumberInput, Paragraph } from '@/components/ui';
import { DurationPicker, formatTimePart, type DurationParts } from '@/components/ui/time-picker';
import { Fonts, MaxContentWidth, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import {
  getIntervalProgram,
  updateIntervalProgram,
  type CueMode,
  type IntervalProgram,
} from '@/lib/interval-programs';

const steps = [
  {
    title: '1. 프로그램 이름',
    description: '알아보기 쉬운 이름으로 수정합니다.',
  },
  {
    title: '2. 준비 시간',
    description: '운동 시작 전에 준비할 시간을 정합니다.',
  },
  {
    title: '3. 운동 시간',
    description: '각 라운드에서 실제로 운동하는 시간을 정합니다.',
  },
  {
    title: '4. 휴식 시간',
    description: '각 라운드 사이에 쉬는 시간을 정합니다.',
  },
  {
    title: '5. 라운드',
    description: '구성한 운동/휴식 세트를 몇 번 반복할지 정합니다.',
  },
  {
    title: '6. 알림 큐',
    description: '비프음 또는 진동을 선택합니다.',
  },
];

function formatTime(value: DurationParts) {
  return `${formatTimePart(value.hours)}:${formatTimePart(value.minutes)}:${formatTimePart(value.seconds)}`;
}

function secondsToDurationParts(totalSeconds: number): DurationParts {
  return {
    hours: Math.floor(totalSeconds / 3600),
    minutes: Math.floor((totalSeconds % 3600) / 60),
    seconds: totalSeconds % 60,
  };
}

function durationPartsToSeconds(value: DurationParts) {
  return value.hours * 3600 + value.minutes * 60 + value.seconds;
}

export default function EditIntervalProgramRoute() {
  const router = useRouter();
  const theme = useTheme();
  const { id } = useLocalSearchParams<{ id: string }>();
  const programId = Number(Array.isArray(id) ? id[0] : id);
  const [program, setProgram] = useState<IntervalProgram | null>(null);
  const [currentStep, setCurrentStep] = useState(0);
  const [name, setName] = useState('');
  const [prepareSeconds, setPrepareSeconds] = useState(10);
  const [workTime, setWorkTime] = useState<DurationParts>({ hours: 0, minutes: 0, seconds: 20 });
  const [restTime, setRestTime] = useState<DurationParts>({ hours: 0, minutes: 0, seconds: 10 });
  const [rounds, setRounds] = useState('8');
  const [cueMode, setCueMode] = useState<CueMode>('beep');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!Number.isFinite(programId)) {
      return;
    }

    let mounted = true;

    void getIntervalProgram(programId).then((nextProgram) => {
      if (!mounted || !nextProgram) {
        return;
      }

      setProgram(nextProgram);
      setName(nextProgram.name);
      setPrepareSeconds(nextProgram.prepareSeconds === 5 ? 5 : 10);
      setWorkTime(secondsToDurationParts(nextProgram.workSeconds));
      setRestTime(secondsToDurationParts(nextProgram.restSeconds));
      setRounds(String(nextProgram.rounds));
      setCueMode(nextProgram.cueMode);
    });

    return () => {
      mounted = false;
    };
  }, [programId]);

  const isLastStep = currentStep === steps.length - 1;
  const canMoveNext = currentStep < steps.length - 1;
  const canSave = isLastStep && name.trim().length > 0 && Number(rounds) > 0 && !saving;
  const summary = useMemo(
    () => `${formatTime(secondsToDurationParts(prepareSeconds))} 준비 / ${formatTime(workTime)} 운동 / ${formatTime(restTime)} 휴식`,
    [prepareSeconds, restTime, workTime],
  );

  const handleSave = async () => {
    if (!canSave) {
      return;
    }

    try {
      setSaving(true);
      await updateIntervalProgram(programId, {
        cueMode,
        name: name.trim(),
        prepareSeconds,
        restSeconds: durationPartsToSeconds(restTime),
        rounds: Number(rounds),
        workSeconds: durationPartsToSeconds(workTime),
      });

      router.replace(`/interval/programs/${programId}` as never);
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
            {[5, 10].map((option) => (
              <Button
                key={option}
                size="lg"
                style={styles.prepareOption}
                variant={prepareSeconds === option ? 'primary' : 'secondary'}
                onPress={() => setPrepareSeconds(option)}>
                {`${option}초`}
              </Button>
            ))}
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
              onPress={() => router.replace(`/interval/programs/${programId}` as never)}
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

          {program ? (
            <>
              <Card>
                <Heading>프로그램 수정</Heading>
                <Paragraph muted>새 프로그램 만들기와 같은 순서로 입력값을 수정합니다.</Paragraph>
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
                  disabled={!canMoveNext}
                  icon={ArrowRight}
                  size="lg"
                  style={styles.navButton}
                  onPress={() => setCurrentStep((step) => Math.min(steps.length - 1, step + 1))}>
                  다음
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
