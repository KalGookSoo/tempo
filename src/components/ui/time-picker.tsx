import { Picker } from '@react-native-picker/picker';
import { useMemo } from 'react';
import { StyleSheet, Text, useWindowDimensions, View } from 'react-native';

import { Fonts, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

export type DurationParts = {
  hours: number;
  minutes: number;
  seconds: number;
};

type TimePickerColumnProps = {
  disabled?: boolean;
  highlighted?: boolean;
  label: string;
  max: number;
  onChange: (value: number) => void;
  value: number;
};

type DurationPickerProps = {
  highlighted?: boolean;
  onChange: (value: DurationParts) => void;
  value: DurationParts;
};

export function formatTimePart(value: number) {
  return String(value).padStart(2, '0');
}

export function TimePickerColumn({
  disabled = false,
  highlighted = false,
  label,
  max,
  onChange,
  value,
}: TimePickerColumnProps) {
  const theme = useTheme();
  const { width } = useWindowDimensions();
  const compact = width < 390;
  const items = useMemo(
    () =>
      Array.from({ length: max + 1 }, (_, itemValue) => {
        const formattedValue = formatTimePart(itemValue);
        return { label: formattedValue, value: String(itemValue) };
      }),
    [max],
  );

  return (
    <View
      accessibilityLabel={label}
      style={[
        styles.pickerColumn,
        compact && styles.compactPickerColumn,
        {
          backgroundColor: highlighted ? theme.primary : theme.surfaceStrong,
          borderColor: theme.border,
          opacity: disabled ? 0.95 : 1,
        },
      ]}>
      {disabled ? (
        <View style={styles.lockedPickerValue}>
          <Text style={[styles.lockedPickerText, { color: highlighted ? '#111111' : theme.text }]}>
            {formatTimePart(value)}
          </Text>
        </View>
      ) : (
        <Picker
          enabled
          dropdownIconColor={theme.text}
          itemStyle={[styles.nativePickerItem, compact && styles.compactNativePickerItem, { color: theme.text }]}
          mode="dropdown"
          prompt={`${label} 선택`}
          selectedValue={String(value)}
          style={[styles.nativePicker, compact && styles.compactNativePicker, { color: theme.text }]}
          onValueChange={(itemValue) => onChange(Number(itemValue))}>
          {items.map((item) => (
            <Picker.Item color={theme.text} key={item.value} label={item.label} value={item.value} />
          ))}
        </Picker>
      )}
      <Text style={[styles.columnLabel, compact && styles.compactColumnLabel, { color: highlighted ? '#111111' : theme.textSecondary }]}>
        {label}
      </Text>
    </View>
  );
}

export function DurationPicker({ highlighted = false, onChange, value }: DurationPickerProps) {
  return (
    <View style={styles.durationPicker}>
      <TimePickerColumn
        highlighted={highlighted}
        label="시간"
        max={99}
        value={value.hours}
        onChange={(hours) => onChange({ ...value, hours })}
      />
      <TimePickerColumn
        highlighted={highlighted}
        label="분"
        max={59}
        value={value.minutes}
        onChange={(minutes) => onChange({ ...value, minutes })}
      />
      <TimePickerColumn
        highlighted={highlighted}
        label="초"
        max={59}
        value={value.seconds}
        onChange={(seconds) => onChange({ ...value, seconds })}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  durationPicker: {
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
    minWidth: 0,
    paddingHorizontal: Spacing.two,
    paddingVertical: Spacing.three,
  },
  compactPickerColumn: {
    borderWidth: 2,
    gap: Spacing.one,
    minHeight: 104,
    paddingHorizontal: 0,
    paddingVertical: Spacing.one,
  },
  nativePicker: {
    alignSelf: 'stretch',
    minHeight: 92,
  },
  compactNativePicker: {
    minHeight: 76,
  },
  nativePickerItem: {
    fontFamily: Fonts.mono,
    fontSize: 16,
    fontWeight: '900',
    letterSpacing: 0,
    lineHeight: 64,
  },
  compactNativePickerItem: {
    fontSize: 10,
    lineHeight: 34,
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
  columnLabel: {
    fontFamily: Fonts.sans,
    fontSize: 12,
    fontWeight: '900',
    lineHeight: 16,
  },
  compactColumnLabel: {
    fontSize: 10,
    lineHeight: 12,
  },
});
