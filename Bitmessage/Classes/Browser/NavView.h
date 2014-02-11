//
//  NavView.h
//  Bitmarket
//
//  Created by Steve Dekorte on 2/5/14.
//  Copyright (c) 2014 Bitmarkets.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NavNode.h"

@interface NavView : NSView

@property (strong, nonatomic) NSMutableArray *navColumns;
@property (strong, nonatomic) id <NavNode> rootNode;


- (BOOL)shouldSelectNode:(id <NavNode>)node inColumn:inColumn;
- (void)stackViews;

@end
