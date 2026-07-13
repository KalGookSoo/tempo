import type { ComponentType, ReactNode } from 'react';
import {
  Linking,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  type TextInputProps,
  type TextProps,
  type TextStyle,
  View,
  type ViewProps,
  type ViewStyle
} from 'react-native';

import { Fonts, type ThemeColor } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

type IconComponent = ComponentType<{
  color?: string;
  size?: number;
  strokeWidth?: number;
}>;

type Tone = 'default' | 'primary' | 'work' | 'rest' | 'prepare' | 'danger';

const toneToColor: Record<Tone, ThemeColor> = {
  default: 'surface',
  primary: 'primary',
  work: 'work',
  rest: 'rest',
  prepare: 'prepare',
  danger: 'danger',
};

function hardShadow(color: string, size: 'sm' | 'md' | 'lg' = 'md'): ViewStyle {
  const offset = size === 'sm' ? 3 : size === 'lg' ? 8 : 5;

  return {
    shadowColor: color,
    shadowOpacity: 1,
    shadowRadius: 0,
    shadowOffset: { width: offset, height: offset },
    elevation: offset,
  };
}

export type HeadingProps = TextProps & {
  level?: 1 | 2 | 3 | 4 | 5 | 6;
};

export function Heading({ level = 1, style, ...props }: HeadingProps) {
  const theme = useTheme();

  return (
    <Text
      accessibilityRole="header"
      style={[styles.textBase, { color: theme.text }, headingStyles[level], style]}
      {...props}
    />
  );
}

export type ParagraphProps = TextProps & {
  size?: 'sm' | 'md' | 'lg';
  muted?: boolean;
};

export function Paragraph({ size = 'md', muted = false, style, ...props }: ParagraphProps) {
  const theme = useTheme();

  return (
    <Text
      style={[
        styles.textBase,
        paragraphStyles[size],
        { color: muted ? theme.textSecondary : theme.text },
        style,
      ]}
      {...props}
    />
  );
}

export type TextVariantProps = TextProps & {
  variant?: 'strong' | 'em' | 'small' | 'caption' | 'code';
};

export function UiText({ variant = 'strong', style, ...props }: TextVariantProps) {
  const theme = useTheme();

  return (
    <Text
      style={[styles.textBase, { color: theme.text }, textVariantStyles[variant], style]}
      {...props}
    />
  );
}

export type UiLinkProps = TextProps & {
  href?: string;
  external?: boolean;
};

export function UiLink({ href, external = false, onPress, style, ...props }: UiLinkProps) {
  const theme = useTheme();

  return (
    <Text
      accessibilityRole="link"
      onPress={(event) => {
        onPress?.(event);
        if (!event.defaultPrevented && href && external) {
          void Linking.openURL(href);
        }
      }}
      style={[styles.textBase, styles.link, { color: theme.link, borderBottomColor: theme.link }, style]}
      {...props}
    />
  );
}

export type ButtonProps = ViewProps & {
  children: ReactNode;
  disabled?: boolean;
  icon?: IconComponent;
  onPress?: () => void;
  size?: 'sm' | 'md' | 'lg';
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost';
};

export function Button({
  children,
  disabled = false,
  icon: Icon,
  onPress,
  size = 'md',
  style,
  variant = 'primary',
  ...props
}: ButtonProps) {
  const theme = useTheme();
  const color = getButtonColor(variant, theme);
  const textColor = getButtonTextColor(variant, theme);

  return (
    <Pressable
      accessibilityRole="button"
      disabled={disabled}
      onPress={onPress}
      style={({ pressed }) => [
        styles.button,
        buttonSizeStyles[size],
        {
          backgroundColor: disabled ? theme.surface : color,
          borderColor: disabled ? theme.textSecondary : theme.border,
          opacity: disabled ? 0.7 : 1,
        },
        variant !== 'ghost' && hardShadow(theme.shadow, pressed ? 'sm' : 'md'),
        pressed && !disabled && styles.pressed,
        style,
      ]}
      {...props}>
      {Icon ? <Icon color={disabled ? theme.textSecondary : textColor} size={20} strokeWidth={2.5} /> : null}
      {typeof children === 'string' || typeof children === 'number' ? (
        <Text style={[styles.buttonText, { color: disabled ? theme.textSecondary : textColor }]}>{children}</Text>
      ) : (
        children
      )}
    </Pressable>
  );
}

export type IconButtonProps = Omit<ButtonProps, 'children' | 'icon'> & {
  icon: IconComponent;
  label: string;
};

export function IconButton({ icon: Icon, label, size = 'md', ...props }: IconButtonProps) {
  const theme = useTheme();
  const iconSize = size === 'sm' ? 18 : size === 'lg' ? 32 : 24;
  const variant = props.variant ?? 'secondary';
  const color = getButtonTextColor(variant, theme);

  return (
    <Button accessibilityLabel={label} size={size} variant={variant} {...props}>
      <Icon color={color} size={iconSize} strokeWidth={2.5} />
    </Button>
  );
}

export type CardProps = ViewProps & {
  tone?: Tone;
};

export function Card({ tone = 'default', style, ...props }: CardProps) {
  const theme = useTheme();
  const backgroundColor = theme[toneToColor[tone]];

  return (
    <View
      style={[
        styles.card,
        { backgroundColor, borderColor: theme.border },
        hardShadow(theme.shadow),
        style,
      ]}
      {...props}
    />
  );
}

export function Divider({ style, ...props }: ViewProps) {
  const theme = useTheme();

  return <View style={[styles.divider, { backgroundColor: theme.border }, style]} {...props} />;
}

export type MenuProps = ViewProps;

export function Menu({ style, ...props }: MenuProps) {
  const theme = useTheme();

  return (
    <View
      accessibilityRole="menu"
      style={[
        styles.menu,
        { backgroundColor: theme.surface, borderColor: theme.border },
        hardShadow(theme.shadow),
        style,
      ]}
      {...props}
    />
  );
}

export type MenuItemProps = ViewProps & {
  destructive?: boolean;
  icon?: IconComponent;
  label: string;
  onPress?: () => void;
  selected?: boolean;
};

export function MenuItem({
  destructive = false,
  icon: Icon,
  label,
  onPress,
  selected = false,
  style,
  ...props
}: MenuItemProps) {
  const theme = useTheme();
  const textColor = selected ? '#111111' : destructive ? theme.danger : theme.text;

  return (
    <Pressable
      accessibilityRole="menuitem"
      onPress={onPress}
      style={({ pressed }) => [
        styles.menuItem,
        {
          backgroundColor: selected ? theme.primary : 'transparent',
          opacity: pressed ? 0.75 : 1,
        },
        style,
      ]}
      {...props}>
      {Icon ? (
        <Icon color={textColor} size={20} strokeWidth={2.5} />
      ) : null}
      <Text style={[styles.menuItemText, { color: textColor }]}>{label}</Text>
    </Pressable>
  );
}

export type ListProps = ViewProps & {
  ordered?: boolean;
  items?: ReactNode[];
};

export function List({ children, items, ordered = false, style, ...props }: ListProps) {
  const content = items?.map((item, index) => (
    <ListItem key={index} marker={ordered ? `${index + 1}.` : '-'}>{item}</ListItem>
  ));

  return (
    <View style={[styles.list, style]} {...props}>
      {content ?? children}
    </View>
  );
}

export type ListItemProps = ViewProps & {
  marker?: string;
};

export function ListItem({ children, marker = '-', style, ...props }: ListItemProps) {
  const theme = useTheme();

  return (
    <View style={[styles.listItem, style]} {...props}>
      <Text style={[styles.listMarker, { color: theme.text }]}>{marker}</Text>
      <View style={styles.listContent}>
        {typeof children === 'string' ? <Paragraph>{children}</Paragraph> : children}
      </View>
    </View>
  );
}

export function UnorderedList(props: Omit<ListProps, 'ordered'>) {
  return <List ordered={false} {...props} />;
}

export function OrderedList(props: Omit<ListProps, 'ordered'>) {
  return <List ordered {...props} />;
}

export type TableProps = ViewProps;

export function Table({ style, ...props }: TableProps) {
  const theme = useTheme();

  return (
    <View
      accessibilityRole="summary"
      style={[styles.table, { borderColor: theme.border }, style]}
      {...props}
    />
  );
}

export type TableRowProps = ViewProps & {
  header?: boolean;
};

export function TableRow({ header = false, style, ...props }: TableRowProps) {
  const theme = useTheme();

  return (
    <View
      style={[styles.tableRow, header && { backgroundColor: theme.primary }, style]}
      {...props}
    />
  );
}

export type TableCellProps = TextProps & {
  header?: boolean;
};

export function TableCell({ header = false, style, ...props }: TableCellProps) {
  const theme = useTheme();

  return (
    <Text
      style={[
        styles.tableCell,
        { borderColor: theme.border, color: header ? '#111111' : theme.text },
        header && styles.tableHeaderCell,
        style,
      ]}
      {...props}
    />
  );
}

export type InputProps = TextInputProps & {
  invalid?: boolean;
};

export function Input({ invalid = false, style, placeholderTextColor, ...props }: InputProps) {
  const theme = useTheme();

  return (
    <TextInput
      placeholderTextColor={placeholderTextColor ?? theme.textSecondary}
      style={[
        styles.input,
        {
          backgroundColor: theme.surfaceStrong,
          borderColor: invalid ? theme.danger : theme.border,
          color: theme.text,
        },
        style,
      ]}
      {...props}
    />
  );
}

export type NumberInputProps = InputProps;

export function NumberInput(props: NumberInputProps) {
  return <Input keyboardType="number-pad" textAlign="center" style={styles.numberInput} {...props} />;
}

function getButtonColor(variant: NonNullable<ButtonProps['variant']>, theme: ReturnType<typeof useTheme>) {
  switch (variant) {
    case 'secondary':
      return theme.surfaceStrong;
    case 'danger':
      return theme.danger;
    case 'ghost':
      return 'transparent';
    case 'primary':
    default:
      return theme.primary;
  }
}

function getButtonTextColor(variant: NonNullable<ButtonProps['variant']>, theme: ReturnType<typeof useTheme>) {
  switch (variant) {
    case 'secondary':
    case 'ghost':
      return theme.text;
    case 'danger':
    case 'primary':
    default:
      return '#111111';
  }
}

const styles = StyleSheet.create({
  textBase: {
    fontFamily: Fonts.sans,
    letterSpacing: 0,
  },
  link: {
    borderBottomWidth: 2,
    fontSize: 16,
    fontWeight: 800,
    lineHeight: 24,
  },
  button: {
    alignItems: 'center',
    borderRadius: 4,
    borderWidth: 3,
    flexDirection: 'row',
    gap: 8,
    justifyContent: 'center',
    minHeight: 44,
  },
  buttonText: {
    fontFamily: Fonts.sans,
    fontSize: 16,
    fontWeight: 900,
    lineHeight: 20,
  },
  pressed: {
    transform: [{ translateX: 2 }, { translateY: 2 }],
  },
  card: {
    borderRadius: 8,
    borderWidth: 3,
    padding: 16,
  },
  divider: {
    height: 2,
    marginVertical: 16,
  },
  menu: {
    borderRadius: 8,
    borderWidth: 3,
    overflow: 'hidden',
    paddingVertical: 4,
  },
  menuItem: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: 10,
    minHeight: 48,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  menuItemText: {
    fontFamily: Fonts.sans,
    fontSize: 16,
    fontWeight: 800,
    lineHeight: 22,
  },
  list: {
    gap: 8,
  },
  listItem: {
    alignItems: 'flex-start',
    flexDirection: 'row',
    gap: 8,
  },
  listMarker: {
    fontFamily: Fonts.mono,
    fontSize: 16,
    fontWeight: 900,
    lineHeight: 24,
    minWidth: 20,
  },
  listContent: {
    flex: 1,
  },
  table: {
    borderLeftWidth: 3,
    borderTopWidth: 3,
  },
  tableRow: {
    flexDirection: 'row',
  },
  tableCell: {
    borderBottomWidth: 3,
    borderRightWidth: 3,
    flex: 1,
    fontFamily: Fonts.sans,
    fontSize: 14,
    fontWeight: 600,
    lineHeight: 20,
    padding: 12,
  },
  tableHeaderCell: {
    fontWeight: 900,
  },
  input: {
    borderRadius: 4,
    borderWidth: 3,
    fontFamily: Fonts.sans,
    fontSize: 16,
    fontWeight: 700,
    minHeight: 48,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  numberInput: {
    fontFamily: Fonts.mono,
    fontSize: 24,
    fontWeight: 900,
  },
});

const headingStyles = StyleSheet.create<Record<NonNullable<HeadingProps['level']>, TextStyle>>({
  1: {
    fontSize: 40,
    fontWeight: 900,
    lineHeight: 48,
  },
  2: {
    fontSize: 32,
    fontWeight: 900,
    lineHeight: 40,
  },
  3: {
    fontSize: 24,
    fontWeight: 800,
    lineHeight: 32,
  },
  4: {
    fontSize: 20,
    fontWeight: 800,
    lineHeight: 28,
  },
  5: {
    fontSize: 18,
    fontWeight: 800,
    lineHeight: 26,
  },
  6: {
    fontSize: 16,
    fontWeight: 800,
    lineHeight: 24,
  },
});

const paragraphStyles = StyleSheet.create<Record<NonNullable<ParagraphProps['size']>, TextStyle>>({
  sm: {
    fontSize: 14,
    fontWeight: 500,
    lineHeight: 20,
  },
  md: {
    fontSize: 16,
    fontWeight: 500,
    lineHeight: 24,
  },
  lg: {
    fontSize: 18,
    fontWeight: 600,
    lineHeight: 28,
  },
});

const textVariantStyles = StyleSheet.create<Record<NonNullable<TextVariantProps['variant']>, TextStyle>>({
  strong: {
    fontWeight: 900,
  },
  em: {
    fontStyle: 'italic',
  },
  small: {
    fontSize: 14,
    fontWeight: 500,
    lineHeight: 20,
  },
  caption: {
    fontSize: 12,
    fontWeight: 700,
    lineHeight: 16,
    textTransform: 'uppercase',
  },
  code: {
    fontFamily: Fonts.mono,
    fontSize: 12,
    fontWeight: 700,
  },
});

const buttonSizeStyles = StyleSheet.create<Record<NonNullable<ButtonProps['size']>, ViewStyle>>({
  sm: {
    minHeight: 44,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  md: {
    minHeight: 48,
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  lg: {
    minHeight: 56,
    paddingHorizontal: 20,
    paddingVertical: 14,
  },
});
