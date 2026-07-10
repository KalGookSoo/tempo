import { useRouter } from 'expo-router';
import { ScrollView, StyleSheet, View } from 'react-native';
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
  const theme = useTheme();

  return (
    <ScrollView style={[styles.screen, { backgroundColor: theme.background }]}>
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.container}>
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
});
