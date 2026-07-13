/**
 * Below are the colors that are used in the app. The colors are defined in the light and dark mode.
 * There are many other ways to style your app. For example, [Nativewind](https://www.nativewind.dev/), [Tamagui](https://tamagui.dev/), [unistyles](https://reactnativeunistyles.vercel.app), etc.
 */

import { Platform } from 'react-native';

export const Palette = {
  ink: '#111111',
  paper: '#FFF8E8',
  chalk: '#F7F7F2',
  night: '#151515',
  coal: '#222222',
  steel: '#676767',
  white: '#FFFFFF',
  red: '#FF4D4D',
  orange: '#FF9F1C',
  yellow: '#FFD447',
  green: '#21C55D',
  cyan: '#00C2FF',
  blue: '#3A86FF',
  pink: '#FF5DA2',
} as const;

export const Colors = {
  light: {
    text: Palette.ink,
    textSecondary: Palette.steel,
    background: Palette.paper,
    backgroundElement: Palette.chalk,
    backgroundSelected: Palette.yellow,
    surface: Palette.chalk,
    surfaceStrong: Palette.white,
    border: Palette.ink,
    shadow: Palette.ink,
    primary: Palette.yellow,
    work: Palette.green,
    rest: Palette.cyan,
    prepare: Palette.orange,
    danger: Palette.red,
    link: Palette.blue,
  },
  dark: {
    text: Palette.white,
    textSecondary: '#CFCFCF',
    background: '#080808',
    backgroundElement: '#1C1C1C',
    backgroundSelected: Palette.yellow,
    surface: '#1C1C1C',
    surfaceStrong: '#2A2A2A',
    border: Palette.white,
    shadow: '#000000',
    primary: Palette.yellow,
    work: Palette.green,
    rest: Palette.cyan,
    prepare: Palette.orange,
    danger: Palette.red,
    link: Palette.blue,
  },
} as const;

export type ThemeColor = keyof typeof Colors.light & keyof typeof Colors.dark;

export const Fonts = Platform.select({
  ios: {
    /** iOS `UIFontDescriptorSystemDesignDefault` */
    sans: 'system-ui',
    /** iOS `UIFontDescriptorSystemDesignSerif` */
    serif: 'ui-serif',
    /** iOS `UIFontDescriptorSystemDesignRounded` */
    rounded: 'ui-rounded',
    /** iOS `UIFontDescriptorSystemDesignMonospaced` */
    mono: 'ui-monospace',
  },
  default: {
    sans: 'normal',
    serif: 'serif',
    rounded: 'normal',
    mono: 'monospace',
  },
  web: {
    sans: 'var(--font-display)',
    serif: 'var(--font-serif)',
    rounded: 'var(--font-rounded)',
    mono: 'var(--font-mono)',
  },
});

export const Spacing = {
  half: 2,
  one: 4,
  two: 8,
  three: 16,
  four: 24,
  five: 32,
  six: 64,
} as const;

export const MaxContentWidth = 800;
