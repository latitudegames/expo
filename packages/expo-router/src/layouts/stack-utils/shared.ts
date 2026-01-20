import type { NativeStackHeaderItemButton } from '@react-navigation/native-stack';
import type { useImage } from 'expo-image';
import { Children, type ReactNode } from 'react';
import { type ColorValue, type ImageSourcePropType, type StyleProp } from 'react-native';
import type { SFSymbol } from 'sf-symbols-typescript';

import { StackToolbarBadge, StackToolbarIcon, StackToolbarLabel } from './common-primitives';
import { getFirstChildOfType } from '../../utils/children';
import { convertTextStyleToRNTextStyle, type BasicTextStyle } from '../../utils/font';

export interface StackHeaderItemSharedProps {
  children?: ReactNode;
  style?: StyleProp<BasicTextStyle>;
  hidesSharedBackground?: boolean;
  separateBackground?: boolean;
  accessibilityLabel?: string;
  accessibilityHint?: string;
  disabled?: boolean;
  tintColor?: ColorValue;
  icon?: `sf:${SFSymbol}` | ImageSourcePropType | (string & {});
  /**
   * @default 'plain'
   */
  variant?: 'plain' | 'done' | 'prominent';
}

export type UseImageSource = Parameters<typeof useImage>[0];

/**
 * Helper to compute image source for useImage hook from the new icon type (with sf: prefix).
 * Returns empty object for SF symbols (they don't need useImage) and passes through other sources.
 * This avoids complex union type computation that TypeScript can't handle.
 */
export function getImageSourceFromIcon(icon: StackHeaderItemSharedProps['icon']): UseImageSource {
  if (!icon) return {};
  return icon as UseImageSource;
}

// We need to pick these properties, as the SharedHeaderItem is not exported by React Navigation
type RNSharedHeaderItem = Pick<
  NativeStackHeaderItemButton,
  | 'label'
  | 'labelStyle'
  | 'icon'
  | 'variant'
  | 'tintColor'
  | 'disabled'
  | 'width'
  | 'hidesSharedBackground'
  | 'sharesBackground'
  | 'identifier'
  | 'badge'
  | 'accessibilityLabel'
  | 'accessibilityHint'
>;

export function convertStackHeaderSharedPropsToRNSharedHeaderItem(
  props: StackHeaderItemSharedProps
): RNSharedHeaderItem {
  const { children, style, separateBackground, icon, ...rest } = props;
  const stringChildren = Children.toArray(children)
    .filter((child) => typeof child === 'string')
    .join('');
  const label = getFirstChildOfType(children, StackToolbarLabel);
  const iconPropConvertedToIcon = props.icon
    ? typeof props.icon === 'string'
      ? props.icon.startsWith('sf:')
        ? { sf: props.icon.slice(3) as SFSymbol } // Remove 'sf:' prefix for RN
        : { src: { uri: props.icon } } // Wrap plain string as image source
      : { src: props.icon } // ImageSourcePropType passed as-is
    : undefined;
  const iconComponentProps =
    getFirstChildOfType(children, StackToolbarIcon)?.props ?? iconPropConvertedToIcon;
  const badgeComponent = getFirstChildOfType(children, StackToolbarBadge);
  const rnsIcon: NativeStackHeaderItemButton['icon'] = (() => {
    if (!iconComponentProps) {
      return undefined;
    }
    if ('src' in iconComponentProps && iconComponentProps.src) {
      return {
        type: 'image',
        source: iconComponentProps.src,
      };
    }
    if ('sf' in iconComponentProps) {
      return {
        type: 'sfSymbol',
        name: iconComponentProps.sf,
      };
    }
    return undefined;
  })();
  const item: RNSharedHeaderItem = {
    ...rest,
    label: label?.props.children ?? stringChildren,
    sharesBackground: !separateBackground,
  };
  if (style) {
    const convertedStyle = convertTextStyleToRNTextStyle(style) ?? {};
    item.labelStyle = convertedStyle;
  }
  if (badgeComponent) {
    item.badge = {
      value: badgeComponent.props.children ?? '',
    };
    const badgeStyle = convertTextStyleToRNTextStyle(badgeComponent.props.style);
    if (badgeStyle) {
      item.badge.style = badgeStyle;
    }
  }
  if (rnsIcon) {
    item.icon = rnsIcon;
  }
  return item;
}
