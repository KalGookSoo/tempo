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
  const medium = width < 430;
  const compact = width < 390;
  const extraCompact = width < 360;
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
        medium && styles.mediumPickerColumn,
        compact && styles.compactPickerColumn,
        extraCompact && styles.extraCompactPickerColumn,
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
          itemStyle={[
            styles.nativePickerItem,
            medium && styles.mediumNativePickerItem,
            compact && styles.compactNativePickerItem,
            extraCompact && styles.extraCompactNativePickerItem,
            { color: theme.text },
          ]}
          mode="dropdown"
          prompt={`${label} 선택`}
          selectedValue={String(value)}
          style={[
            styles.nativePicker,
            medium && styles.mediumNativePicker,
            compact && styles.compactNativePicker,
            extraCompact && styles.extraCompactNativePicker,
            { color: theme.text },
          ]}
          onValueChange={(itemValue) => onChange(Number(itemValue))}>
          {items.map((item) => (
            <Picker.Item color={theme.text} key={item.value} label={item.label} value={item.value} />
          ))}
        </Picker>
      )}
      <Text
        style={[
          styles.columnLabel,
          medium && styles.mediumColumnLabel,
          compact && styles.compactColumnLabel,
          extraCompact && styles.extraCompactColumnLabel,
          { color: highlighted ? '#111111' : theme.textSecondary },
        ]}>
        {label}
      </Text>
    </View>
  );
}

export function DurationPicker({ highlighted = false, onChange, value }: DurationPickerProps) {
  const { width } = useWindowDimensions();
  const medium = width < 430;
  const compact = width < 390;
  const extraCompact = width < 360;

  return (
    <View
      style={[
        styles.durationPicker,
        medium && styles.mediumDurationPicker,
        compact && styles.compactDurationPicker,
        extraCompact && styles.extraCompactDurationPicker,
      ]}>
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
  mediumDurationPicker: {
    gap: Spacing.one,
  },
  compactDurationPicker: {
    gap: Spacing.half,
  },
  extraCompactDurationPicker: {
    gap: 1,
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
  mediumPickerColumn: {
    borderWidth: 2,
    gap: Spacing.one,
    minHeight: 112,
    paddingHorizontal: Spacing.one,
    paddingVertical: Spacing.two,
  },
  compactPickerColumn: {
    minHeight: 104,
    paddingHorizontal: 0,
    paddingVertical: Spacing.one,
  },
  extraCompactPickerColumn: {
    borderWidth: 1,
    minHeight: 96,
  },
  nativePicker: {
    alignSelf: 'stretch',
    fontFamily: Fonts.mono,
    fontSize: 16,
    fontWeight: '900',
    minHeight: 92,
    width: '100%',
  },
  mediumNativePicker: {
    fontSize: 12,
    minHeight: 82,
  },
  compactNativePicker: {
    fontSize: 9,
    minHeight: 76,
  },
  extraCompactNativePicker: {
    fontSize: 8,
    minHeight: 68,
  },
  nativePickerItem: {
    fontFamily: Fonts.mono,
    fontSize: 16,
    fontWeight: '900',
    letterSpacing: 0,
    lineHeight: 64,
  },
  mediumNativePickerItem: {
    fontSize: 12,
    lineHeight: 42,
  },
  compactNativePickerItem: {
    fontSize: 9,
    lineHeight: 30,
  },
  extraCompactNativePickerItem: {
    fontSize: 8,
    lineHeight: 26,
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
  mediumColumnLabel: {
    fontSize: 11,
    lineHeight: 14,
  },
  compactColumnLabel: {
    fontSize: 10,
    lineHeight: 12,
  },
  extraCompactColumnLabel: {
    fontSize: 9,
    lineHeight: 10,
  },
});
