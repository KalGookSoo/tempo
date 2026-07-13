export type IntervalHelpGuide = {
  customNote?: string;
  description: string;
  id: string;
  steps: string[];
  title: string;
};

export const intervalHelpGuides: IntervalHelpGuide[] = [
  {
    description: '20초 운동과 10초 휴식을 8라운드 반복하는 짧고 강한 인터벌입니다.',
    id: 'tabata',
    steps: [
      '새 프로그램에서 이름을 Tabata로 입력합니다.',
      '준비 시간은 00:00:10처럼 짧게 둡니다.',
      '운동 시간은 00:00:20으로 입력합니다.',
      '휴식 시간은 00:00:10으로 입력합니다.',
      '라운드 수는 8로 입력하고 저장합니다.',
    ],
    title: 'Tabata',
  },
  {
    description: 'Every Minute On the Minute의 약자입니다. 매 분마다 정해진 동작을 시작하는 방식입니다.',
    id: 'emom',
    steps: [
      '새 프로그램에서 이름을 EMOM 10처럼 입력합니다.',
      '준비 시간은 필요에 따라 00:00:10 정도로 둡니다.',
      '운동 시간은 00:01:00으로 입력합니다.',
      '휴식 시간은 00:00:00으로 입력합니다.',
      '라운드 수는 진행할 분 수만큼 입력합니다. 예: 10분 EMOM은 10라운드입니다.',
    ],
    title: 'EMOM',
  },
  {
    description: '여러 운동 구간을 연속으로 돌고 라운드 사이에 휴식을 두는 방식입니다.',
    id: 'fgb',
    steps: [
      'MVP에서는 운동/휴식 한 쌍을 먼저 만들어 반복 구조로 저장합니다.',
      '준비 시간은 00:00:10처럼 짧게 둡니다.',
      '운동 시간은 한 구간의 작업 시간으로 입력합니다. 예: 00:01:00.',
      '휴식 시간은 구간 사이 또는 라운드 사이 휴식 기준으로 입력합니다.',
      '라운드 수는 전체 반복 횟수로 입력합니다.',
    ],
    title: 'FGB 스타일',
  },
  {
    customNote: '운동과 휴식 시간을 조합하면 러닝, 서킷, 스트레칭, 재활 루틴처럼 정해진 이름이 없는 반복 프로그램도 만들 수 있습니다.',
    description: '준비, 운동, 휴식, 라운드, 알림 큐를 직접 조합해 만드는 일반 인터벌입니다.',
    id: 'custom',
    steps: [
      '새 프로그램에서 목적이 드러나는 이름을 입력합니다. 예: 러닝 40/20, 하체 서킷, 스트레칭 루틴.',
      '운동 전 준비 시간이 필요하면 준비 시간을 입력합니다.',
      '한 라운드의 운동 시간을 입력합니다.',
      '라운드 사이에 필요한 휴식 시간을 입력합니다.',
      '반복할 라운드 수와 알림 큐를 선택하고 저장합니다.',
    ],
    title: '사용자 커스텀',
  },
];

export function getIntervalHelpGuide(id: string) {
  return intervalHelpGuides.find((guide) => guide.id === id) ?? null;
}
