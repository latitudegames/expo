import type { NativeStackHeaderItemButton } from '@react-navigation/native-stack';
import type { useImage } from 'expo-image';
import { type ReactNode } from 'react';
import { type ColorValue, type ImageSourcePropType, type StyleProp } from 'react-native';
import type { SFSymbol } from 'sf-symbols-typescript';
import { type BasicTextStyle } from '../../utils/font';
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
export declare function getImageSourceFromIcon(icon: StackHeaderItemSharedProps['icon']): UseImageSource;
type RNSharedHeaderItem = Pick<NativeStackHeaderItemButton, 'label' | 'labelStyle' | 'icon' | 'variant' | 'tintColor' | 'disabled' | 'width' | 'hidesSharedBackground' | 'sharesBackground' | 'identifier' | 'badge' | 'accessibilityLabel' | 'accessibilityHint'>;
export declare function convertStackHeaderSharedPropsToRNSharedHeaderItem(props: StackHeaderItemSharedProps): RNSharedHeaderItem;
export {};
//# sourceMappingURL=shared.d.ts.map