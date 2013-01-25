//
//  CXADirectoryContentsWatcher.h
//  CXADirectoryContentsWatcher
//
//  Copyright (c) 2013 CHEN Xian'an <xianan.chen@gmail.com>. All rights reserved.
//
//  CXADirectoryContentsWatcher is released under the MIT license. In short, it's royalty-free but you must you keep the copyright notice in your code or software distribution.

#import <Foundation/Foundation.h>

@class CXADirectoryContentsWatcher;
@protocol CXADirectoryContentsWatcherDelegate <NSObject>

- (void)directoryWatcher:(CXADirectoryContentsWatcher *)dirWatcher didFinishCopyItemAtURL:(NSURL *)fileURL isReplacement:(BOOL)isReplacement;
- (void)directoryWatcher:(CXADirectoryContentsWatcher *)dirWatcher didRemoveItemAtURL:(NSURL *)fileURL;

@end

@interface CXADirectoryContentsWatcher : NSObject

@property (nonatomic, weak) id <CXADirectoryContentsWatcherDelegate> delegate;
@property (nonatomic, strong, readonly) NSURL *directoryURL;

- (instancetype)initWithDirectoryURL:(NSURL *)dirURL delegate:(id <CXADirectoryContentsWatcherDelegate>)delegate;
- (BOOL)start;
- (void)stop;

@end
