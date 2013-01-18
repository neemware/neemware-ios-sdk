//
//  NW_DTCustomColoredAccessory.h
//  NWSDKTestApp
//
//  Created by Erik Stromlund (Neemware) on 8/10/12.
//  Copyright (c) 2013 Neemware, Inc. All rights reserved.
//
//  From: http://www.cocoanetics.com/2010/10/custom-colored-disclosure-indicators/

@interface NW_DTCustomColoredAccessory : UIControl
{
	UIColor *_accessoryColor;
	UIColor *_highlightedColor;
}

@property (nonatomic, retain) UIColor *accessoryColor;
@property (nonatomic, retain) UIColor *highlightedColor;

+ (NW_DTCustomColoredAccessory *)accessoryWithColor:(UIColor *)color;

@end