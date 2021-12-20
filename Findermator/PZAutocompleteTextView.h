//
//  NCAutocompleteTextView.h
//  Example
//
//  Created by Daniel Weber on 9/28/14.
//  Copyright (c) 2014 Null Creature. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol PZAutocompleteTableViewDelegate <NSObject>
@optional
- (NSImage *)textView:(NSTextView *)textView imageForCompletion:(NSString *)word;
- (NSString *)textView:(NSTextView *)textView labelForCompletion:(NSString *)word;
- (NSArray<NSString *> *)textView:(NSTextView *)textView completions:(NSArray<NSString *> *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index;
@end

@interface PZAutocompleteTextView : NSTextView <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, weak) id <PZAutocompleteTableViewDelegate> autocompleteDelegate;

@end
