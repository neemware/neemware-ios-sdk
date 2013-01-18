//
//  NWFeedbackConstants.h
//
//  Created by Puru Choudhary on 12/11/11.
//  Modified by Erik Stromlund on 12/15/2012
//  Copyright (c) 2013 Neemware. All rights reserved.
//

#define NW_RELEASE_SAFELY(__POINTER) { if (__POINTER) {[__POINTER release]; __POINTER = nil;} }

#define UIColorFromRGB(rgbValue) [UIColor \
                                  colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
                                  green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
                                  blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]