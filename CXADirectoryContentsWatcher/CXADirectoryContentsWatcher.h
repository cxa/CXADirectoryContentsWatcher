//
//  CXADirectoryContentsWatcher.h
//  CXADirectoryContentsWatcher
//
//  Created by CHEN Xian’an on 3/19/15.
//  Copyright (c) 2015 lazyapps. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for CXADirectoryContentsWatcher.
FOUNDATION_EXPORT double CXADirectoryContentsWatcherVersionNumber;

//! Project version string for CXADirectoryContentsWatcher.
FOUNDATION_EXPORT const unsigned char CXADirectoryContentsWatcherVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <CXADirectoryContentsWatcher/PublicHeader.h>

#import <Foundation/Foundation.h>

#if !__has_feature(nullability)
#define NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_END
#define __nullable
#endif

NS_ASSUME_NONNULL_BEGIN

@class CXADirectoryContentsWatcher;
@protocol CXADirectoryContentsWatcherDelegate <NSObject>

- (void)directoryWatcher:(CXADirectoryContentsWatcher * )dirWatcher didFinishCopyItemAtURL:(NSURL *)fileURL isReplacement:(BOOL)isReplacement;
- (void)directoryWatcher:(CXADirectoryContentsWatcher *)dirWatcher didRemoveItemAtURL:(NSURL *)fileURL;

@end

typedef void (^CXADirectoryContentsWatcherFinishCopyItemHandler)(NSURL *fileURL, BOOL isReplacement);

typedef void (^CXADirectoryContentsWatcherRemoveItemHandler)(NSURL *fileURL);

@interface CXADirectoryContentsWatcher : NSObject

@property (nonatomic, strong, readonly) NSURL *directoryURL;
@property (nonatomic, weak) id <CXADirectoryContentsWatcherDelegate> __nullable delegate;
@property (nonatomic, copy) CXADirectoryContentsWatcherFinishCopyItemHandler __nullable finishCopyHandler;
@property (nonatomic, copy) CXADirectoryContentsWatcherRemoveItemHandler __nullable removeItemHandler;

- (instancetype)initWithDirectoryURL:(NSURL *)dirURL delegate:(id <CXADirectoryContentsWatcherDelegate>)delegate;
- (BOOL)start;
- (void)stop;

NS_ASSUME_NONNULL_END

@end
