//
//  TestMainViewController.h
//  NeemwareSDK
//
//  Created by Erik Stromlund (neemware) on 8/7/12.
//  Copyright (c) 2012 Neemware, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TestMainViewController : UIViewController

- (IBAction)showInbox:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *latitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *longitudeField;

@end