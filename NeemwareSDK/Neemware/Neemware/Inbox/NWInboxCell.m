//
//  NWInboxCell.m
//  NeemwareSDK
//
//  Created by Erik Stromlund (Neemware) on 8/8/12.
//  Copyright (c) 2013 Neemware, Inc. All rights reserved.
//

#import "NWInboxCell.h"

static const NSInteger kDistanceFromLeftEdge = 7;
static const NSInteger kBoxEdgeSize = 24;


@implementation NWInboxCell

@synthesize contentImageView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        if (!self.contentImageView)
        {
            contentImageView = [[UIImageView alloc] initWithFrame:CGRectMake(kDistanceFromLeftEdge,
                                                                             (self.frame.size.height - kBoxEdgeSize)/2,
                                                                             kBoxEdgeSize,
                                                                             kBoxEdgeSize)];
            
            [self.contentView addSubview:contentImageView];
        }
    }
    return self;
}

// This method shifts everything in a standard UITableViewCell to the right
// and then creates a square contentImageView on the left side of the cell, with side length boxEdgeSize
- (void)layoutSubviews
{
    // Make sure normal configuration happens
    [super layoutSubviews];

    // Make sure the frame is where we want it (because we resize the standard TVC in the UITableViewController the image will be off a bit otherwise)
    contentImageView.frame = CGRectMake(kDistanceFromLeftEdge, (self.frame.size.height - kBoxEdgeSize)/2, kBoxEdgeSize, kBoxEdgeSize);
    
    // Make frame references for later
    CGRect dtlFrame = self.detailTextLabel.frame;
    CGRect tlFrame = self.textLabel.frame;
    CGRect contViewFrame = self.contentView.frame;
    
    // Shrink the textLabel view by size of boxEdgeSize, and shift that much right plus offset from leftEdge
    self.textLabel.frame = CGRectMake(tlFrame.origin.x + kBoxEdgeSize + kDistanceFromLeftEdge,
                                      tlFrame.origin.y,
                                      contViewFrame.size.width - (2*kDistanceFromLeftEdge + kBoxEdgeSize + 7),
                                      tlFrame.size.height);

    // Shrink the detailTextLabel view by size of boxEdgeSize, and shift that much right plus offset from leftEdge
    self.detailTextLabel.frame = CGRectMake(dtlFrame.origin.x + kBoxEdgeSize + kDistanceFromLeftEdge,
                                            dtlFrame.origin.y,
                                            contViewFrame.size.width - (2*kDistanceFromLeftEdge + kBoxEdgeSize + 7),
                                            dtlFrame.size.height);
}
@end
