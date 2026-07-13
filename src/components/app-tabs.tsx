import { Tabs } from 'expo-router';
import { useColorScheme } from 'react-native';

import { Colors } from '@/constants/theme';

export default function AppTabs() {
  const scheme = useColorScheme();
  const colors = Colors[scheme === 'dark' ? 'dark' : 'light'];

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: colors.text,
        tabBarInactiveTintColor: colors.textSecondary,
        tabBarStyle: {
          backgroundColor: colors.background,
          borderTopColor: colors.border,
        },
      }}>
      <Tabs.Screen name="index" options={{ title: '타이머' }} />
      <Tabs.Screen name="presets/index" options={{ title: '프리셋' }} />
      <Tabs.Screen name="settings/index" options={{ title: '설정' }} />
      <Tabs.Screen name="explore" options={{ href: null }} />
      <Tabs.Screen name="history/index" options={{ href: null }} />
      <Tabs.Screen name="history/[id]/index" options={{ href: null }} />
      <Tabs.Screen name="presets/default/[id]/index" options={{ href: null }} />
      <Tabs.Screen name="presets/custom/[id]/index" options={{ href: null }} />
      <Tabs.Screen name="presets/custom/[id]/edit/index" options={{ href: null }} />
      <Tabs.Screen name="presets/new/index" options={{ href: null }} />
      <Tabs.Screen name="settings/display/index" options={{ href: null }} />
      <Tabs.Screen name="settings/notification-cues/index" options={{ href: null }} />
      <Tabs.Screen name="settings/sounds/index" options={{ href: null }} />
      <Tabs.Screen name="timer/count-up/index" options={{ href: null }} />
      <Tabs.Screen name="timer/countdown/index" options={{ href: null }} />
      <Tabs.Screen name="timer/interval/index" options={{ href: null }} />
      <Tabs.Screen name="timer/run/index" options={{ href: null }} />
      <Tabs.Screen name="timer/stopwatch/index" options={{ href: null }} />
    </Tabs>
  );
}
