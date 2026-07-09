/** @type {import('tailwindcss').Config} */
const palette = {
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
};

const semanticColors = {
  light: {
    bg: palette.paper,
    surface: palette.chalk,
    surfaceStrong: palette.white,
    text: palette.ink,
    textMuted: palette.steel,
    border: palette.ink,
    shadow: palette.ink,
    primary: palette.yellow,
    work: palette.green,
    rest: palette.cyan,
    prepare: palette.orange,
    danger: palette.red,
    link: palette.blue,
  },
  dark: {
    bg: palette.night,
    surface: palette.coal,
    surfaceStrong: '#2D2D2D',
    text: palette.white,
    textMuted: '#B8B8B8',
    border: palette.white,
    shadow: '#000000',
    primary: palette.yellow,
    work: palette.green,
    rest: palette.cyan,
    prepare: palette.orange,
    danger: palette.red,
    link: palette.blue,
  },
};

module.exports = {
  content: ['./src/**/*.{js,jsx,ts,tsx}', './app/**/*.{js,jsx,ts,tsx}'],
  presets: [require('nativewind/preset')],
  theme: {
    extend: {
      colors: {
        tempo: palette,
        light: semanticColors.light,
        dark: semanticColors.dark,
      },
    },
  },
  plugins: [],
};
