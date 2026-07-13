import { usePathname, useRouter } from 'expo-router';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Button, Card, Heading, Paragraph } from '@/components/ui';
import { BottomTabInset, MaxContentWidth, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

export type RouteLink = {
  href: string;
  label: string;
};

export type RoutePlaceholderProps = {
  description: string;
  links?: RouteLink[];
  title: string;
};

export function RoutePlaceholder({ description, links = [], title }: RoutePlaceholderProps) {
  const router = useRouter();
  const pathname = usePathname();
  const theme = useTheme();
  const canGoBack = router.canGoBack();
  const showBackButton = pathname !== '/';

  return (
    <ScrollView style={[styles.screen, { backgroundColor: theme.background }]}>
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.container}>
          {showBackButton ? (
            <Pressable
              accessibilityRole="button"
              onPress={() => (canGoBack ? router.back() : router.replace('/'))}
              style={({ pressed }) => [
                styles.backButton,
                { backgroundColor: theme.surface, borderColor: theme.border },
                pressed && styles.pressed,
              ]}>
              <Text style={[styles.backButtonText, { color: theme.text }]}>← 뒤로</Text>
            </Pressable>
          ) : null}

          <Card>
            <Heading>{title}</Heading>
            <Paragraph muted>{description}</Paragraph>
          </Card>

          {links.length > 0 ? (
            <View style={styles.links}>
              {links.map((link) => (
                <Button key={link.href} variant="secondary" onPress={() => router.push(link.href as never)}>
                  {link.label}
                </Button>
              ))}
            </View>
          ) : null}
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
    paddingBottom: BottomTabInset + Spacing.three,
    paddingHorizontal: Spacing.four,
    paddingTop: Spacing.four,
  },
  container: {
    flex: 1,
    gap: Spacing.four,
    width: '100%',
    maxWidth: MaxContentWidth,
  },
  links: {
    gap: Spacing.three,
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
  pressed: {
    opacity: 0.75,
    transform: [{ translateX: 1 }, { translateY: 1 }],
  },
});
